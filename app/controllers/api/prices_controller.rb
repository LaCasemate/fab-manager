# frozen_string_literal: true

# API Controller for resources of type Price
# Prices are used in reservations (Machine, Space)
class API::PricesController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize Price
    @prices = Price.all
    if params[:priceable_type]
      @prices = @prices.where(priceable_type: params[:priceable_type])

      @prices = @prices.where(priceable_id: params[:priceable_id]) if params[:priceable_id]
    end
    if params[:plan_id]
      plan_id = if /no|nil|null|undefined/i.match?(params[:plan_id])
                  nil
                else
                  params[:plan_id]
                end
      @prices = @prices.where(plan_id: plan_id)
    end
    @prices = @prices.where(group_id: params[:group_id]) if params[:group_id]
  end

  def update
    authorize Price
    @price = Price.find(params[:id])
    price_parameters = price_params
    price_parameters[:amount] = price_parameters[:amount] * 100
    if @price.update(price_parameters)
      render status: :ok
    else
      render status: :unprocessable_entity
    end
  end

  def compute
    cs = CartService.new(current_user)
    cart = cs.from_hash(params)
    @amount = cart.total
  end

  private

  def price_params
    params.require(:price).permit(:amount)
  end

  def compute_reservation_price_params
    params.require(:reservation).permit(:reservable_id, :reservable_type, :plan_id, :user_id, :nb_reserve_places, :payment_schedule,
                                        tickets_attributes: %i[event_price_category_id booked],
                                        slots_attributes: %i[id start_at end_at availability_id offered])
  end

  def compute_subscription_price_params
    params.require(:subscription).permit(:plan_id, :user_id, :payment_schedule)
  end

  def coupon_params
    params.permit(:coupon_code)
  end
end
