# frozen_string_literal: true

# API Controller for handling the payments process in the front-end, using the Stripe gateway
class API::StripeController < API::PaymentsController
  require 'stripe/helper'

  ##
  # Client requests to confirm a card payment will ask this endpoint.
  # It will check for the need of a strong customer authentication (SCA) to confirm the payment or confirm that the payment
  # was successfully made. After the payment was made, the reservation/subscription will be created
  ##
  def confirm_payment
    render(json: { error: 'Bad gateway or online payment is disabled' }, status: :bad_gateway) and return unless Stripe::Helper.enabled?

    amount = nil # will contains the amount and the details of each invoice lines
    intent = nil # stripe's payment intent
    res = nil # json of the API answer

    begin
      amount = card_amount
      if params[:payment_method_id].present?
        check_coupon
        check_plan

        # Create the PaymentIntent
        intent = Stripe::PaymentIntent.create(
          {
            payment_method: params[:payment_method_id],
            amount: amount[:amount],
            currency: Setting.get('stripe_currency'),
            confirmation_method: 'manual',
            confirm: true,
            customer: current_user.payment_gateway_object.gateway_object_id
          }, { api_key: Setting.get('stripe_secret_key') }
        )
      elsif params[:payment_intent_id].present?
        intent = Stripe::PaymentIntent.confirm(params[:payment_intent_id], api_key: Setting.get('stripe_secret_key'))
      end
    rescue Stripe::CardError => e
      # Display error on client
      res = { status: 200, json: { error: e.message } }
    rescue InvalidCouponError
      res = { json: { coupon_code: 'wrong coupon code or expired' }, status: :unprocessable_entity }
    rescue InvalidGroupError
      res = { json: { plan_id: 'this plan is not compatible with your current group' }, status: :unprocessable_entity }
    end

    if intent&.status == 'succeeded'
      if params[:cart_items][:reservation]
        res = on_reservation_success(intent, amount[:details])
      elsif params[:cart_items][:subscription]
        res = on_subscription_success(intent, amount[:details])
      end
    end

    render generate_payment_response(intent, res)
  end

  def online_payment_status
    authorize :payment

    key = Setting.get('stripe_secret_key')
    render json: { status: false } and return unless key&.present?

    charges = Stripe::Charge.list({ limit: 1 }, { api_key: key })
    render json: { status: charges.data.length.positive? }
  rescue Stripe::AuthenticationError
    render json: { status: false }
  end

  def setup_intent
    user = User.find(params[:user_id])
    key = Setting.get('stripe_secret_key')
    @intent = Stripe::SetupIntent.create({ customer: user.payment_gateway_object.gateway_object_id }, { api_key: key })
    render json: { id: @intent.id, client_secret: @intent.client_secret }
  end

  def confirm_payment_schedule
    key = Setting.get('stripe_secret_key')
    intent = Stripe::SetupIntent.retrieve(params[:setup_intent_id], api_key: key)

    amount = card_amount
    if intent&.status == 'succeeded'
      if params[:cart_items][:reservation]
        res = on_reservation_success(intent, amount[:details])
      elsif params[:cart_items][:subscription]
        res = on_subscription_success(intent, amount[:details])
      end
    end

    render generate_payment_response(intent, res)
  rescue Stripe::InvalidRequestError => e
    render json: e, status: :unprocessable_entity
  end

  def update_card
    user = User.find(params[:user_id])
    key = Setting.get('stripe_secret_key')
    Stripe::Customer.update(user.payment_gateway_object.gateway_object_id,
                            { invoice_settings: { default_payment_method: params[:payment_method_id] } },
                            { api_key: key })
    render json: { updated: true }, status: :ok
  rescue Stripe::StripeError => e
    render json: { updated: false, error: e }, status: :unprocessable_entity
  end

  private

  def post_reservation_save(intent_id, intent_type)
    return unless intent_type == 'Stripe::PaymentIntent'

    Stripe::PaymentIntent.update(
      intent_id,
      { description: "Invoice reference: #{@reservation.invoice.reference}" },
      { api_key: Setting.get('stripe_secret_key') }
    )
  end

  def post_subscription_save(intent_id, intent_type)
    return unless intent_type == 'Stripe::PaymentIntent'

    Stripe::PaymentIntent.update(
      intent_id,
      { description: "Invoice reference: #{@subscription.invoices.first.reference}" },
      { api_key: Setting.get('stripe_secret_key') }
    )
  end

  def on_reservation_success(intent, details)
    super(intent.id, intent.class.name, details)
  end

  def on_subscription_success(intent, details)
    super(intent.id, intent.class.name, details)
  end

  def generate_payment_response(intent, res = nil)
    return res unless res.nil?

    if intent.status == 'requires_action' && intent.next_action.type == 'use_stripe_sdk'
      # Tell the client to handle the action
      {
        status: 200,
        json: {
          requires_action: true,
          payment_intent_client_secret: intent.client_secret
        }
      }
    elsif intent.status == 'succeeded'
      # The payment didn't need any additional actions and is completed!
      # Handle post-payment fulfillment
      { status: 200, json: { success: true } }
    else
      # Invalid status
      { status: 500, json: { error: 'Invalid PaymentIntent status' } }
    end
  end
end
