# frozen_string_literal: true

# Abstract API Controller to be extended by each gateway, for handling the payments processes in the front-end
class API::PaymentsController < API::ApiController
  before_action :authenticate_user!


  # This method must be overridden by the the gateways controllers that inherits API::PaymentsControllers
  def confirm_payment
    raise NoMethodError
  end

  protected

  def post_reservation_save(_gateway_item_id, _gateway_item_type); end

  def post_subscription_save(_gateway_item_id, _gateway_item_type); end

  def get_wallet_debit(user, total_amount)
    wallet_amount = (user.wallet.amount * 100).to_i
    wallet_amount >= total_amount ? total_amount : wallet_amount
  end

  def card_amount
    cs = CartService.new(current_user)
    cart = cs.from_hash(params[:cart_items])
    price_details = cart.total

    # Subtract wallet amount from total
    total = price_details[:total]
    wallet_debit = get_wallet_debit(current_user, total)
    { amount: total - wallet_debit, details: price_details }
  end

  def check_coupon
    return if coupon_params[:coupon_code].nil?

    coupon = Coupon.find_by(code: coupon_params[:coupon_code])
    raise InvalidCouponError if coupon.nil? || coupon.status(current_user.id) != 'active'
  end

  def check_plan
    plan_id = (cart_items_params[:subscription][:plan_id] if cart_items_params[:subscription])

    return unless plan_id

    plan = Plan.find(plan_id)
    raise InvalidGroupError if plan.group_id != current_user.group_id
  end

  def on_reservation_success(gateway_item_id, gateway_item_type, details)
    @reservation = Reservation.new(reservation_params)
    if params[:cart_items][:subscription] && params[:cart_items][:subscription][:plan_id]
      @reservation.plan_id = params[:cart_items][:subscription][:plan_id]
    end
    payment_method = params[:cart_items][:reservation][:payment_method] || 'card'
    user_id = if current_user.admin? || current_user.manager?
                params[:cart_items][:reservation][:user_id]
              else
                current_user.id
              end
    is_reserve = Reservations::Reserve.new(user_id, current_user.invoicing_profile.id)
                                      .pay_and_save(@reservation,
                                                    payment_details: details,
                                                    payment_id: gateway_item_id,
                                                    payment_type: gateway_item_type,
                                                    schedule: params[:cart_items][:payment_schedule],
                                                    payment_method: payment_method)
    post_reservation_save(gateway_item_id, gateway_item_type)

    if is_reserve
      SubscriptionExtensionAfterReservation.new(@reservation).extend_subscription_if_eligible

      { template: 'api/reservations/show', status: :created, location: @reservation }
    else
      { json: @reservation.errors, status: :unprocessable_entity }
    end
  end

  def on_subscription_success(gateway_item_id, gateway_item_type, details)
    @subscription = Subscription.new(subscription_params)
    user_id = if current_user.admin? || current_user.manager?
                params[:cart_items][:customer_id]
              else
                current_user.id
              end
    is_subscribe = Subscriptions::Subscribe.new(current_user.invoicing_profile.id, user_id)
                                           .pay_and_save(@subscription,
                                                         payment_details: details,
                                                         payment_id: gateway_item_id,
                                                         payment_type: gateway_item_type,
                                                         schedule: params[:cart_items][:subscription][:payment_schedule],
                                                         payment_method: 'card')

    post_subscription_save(gateway_item_id, gateway_item_type)

    if is_subscribe
      { template: 'api/subscriptions/show', status: :created, location: @subscription }
    else
      { json: @subscription.errors, status: :unprocessable_entity }
    end
  end

  def reservation_params
    params[:cart_items].require(:reservation).permit(:reservable_id, :reservable_type, :nb_reserve_places,
                                                     tickets_attributes: %i[event_price_category_id booked],
                                                     slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def subscription_params
    params[:cart_items].require(:subscription).permit(:plan_id)
  end

  def cart_items_params
    params.require(:cart_items).permit(subscription: :plan_id,
                                       reservation: [
                                         :reservable_id, :reservable_type, :nb_reserve_places,
                                         tickets_attributes: %i[event_price_category_id booked],
                                         slots_attributes: %i[id start_at end_at availability_id offered]
                                       ])
  end

  def coupon_params
    params.require(:cart_items).permit(:coupon_code)
  end
end
