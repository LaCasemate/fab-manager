# frozen_string_literal: true

# create remote items on currently active payment gateway
class PaymentGatewayService
  def initialize
    @gateway = if Stripe::Helper.enabled?
                 require 'stripe/service'
                 Stripe::Service
               elsif PayZen::Helper.enabled?
                 require 'pay_zen/service'
                 PayZen::Service
               else
                 require 'payment/service'
                 Payment::Service
               end
  end

  def create_subscription(payment_schedule, gateway_object_id)
    @gateway.create_subscription(payment_schedule, gateway_object_id)
  end

  def create_coupon(coupon_id)
    @gateway.create_coupon(coupon_id)
  end

  def delete_coupon(coupon_id)
    @gateway.delete_coupon(coupon_id)
  end

  def create_or_update_product(klass, id)
    @gateway.create_or_update_product(klass, id)
  end
end
