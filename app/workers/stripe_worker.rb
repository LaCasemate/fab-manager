# frozen_string_literal: true

# This worker perform various requests to the Stripe API (payment service)
class StripeWorker
  require 'stripe/helper'
  include Sidekiq::Worker
  sidekiq_options queue: :stripe

  def perform(action, *params)
    return false unless Stripe::Helper.enabled?

    send(action, *params)
  end

  def create_stripe_customer(user_id)
    user = User.find(user_id)
    customer = Stripe::Customer.create(
      {
        description: user.profile.full_name,
        email: user.email
      },
      { api_key: Setting.get('stripe_secret_key') }
    )
    user.update_columns(stp_customer_id: customer.id)
  end

  def delete_stripe_coupon(coupon_code)
    cpn = Stripe::Coupon.retrieve(coupon_code, api_key: Setting.get('stripe_secret_key'))
    cpn.delete
  rescue Stripe::InvalidRequestError => e
    STDERR.puts "WARNING: Unable to delete the coupon on Stripe: #{e}"
  end

  def create_or_update_stp_product(class_name, id)
    object = class_name.constantize.find(id)
    if !object.payment_gateway_object.nil?
      Stripe::Product.update(
        object.payment_gateway_object.gateway_object_id,
        { name: object.name },
        { api_key: Setting.get('stripe_secret_key') }
      )
    else
      product = Stripe::Product.create(
        {
          name: object.name,
          metadata: {
            id: object.id,
            type: class_name
          }
        }, { api_key: Setting.get('stripe_secret_key') }
      )
      pgo = PaymentGatewayObject.new(item: object)
      pgo.gateway_object = product
      pgo.save!
      puts "Stripe product was created for the #{class_name} \##{id}"
    end

  rescue Stripe::InvalidRequestError
    obj_id = object.payment_gateway_object.gateway_object_id
    STDERR.puts "WARNING: saved payment_gateway_object#id (#{obj_id}) does not match on Stripe, recreating..."
    product = Stripe::Product.create(
      {
        name: object.name,
        metadata: {
          id: object.id,
          type: class_name
        }
      }, { api_key: Setting.get('stripe_secret_key') }
    )
    pgo = PaymentGatewayObject.new(item: object)
    pgo.gateway_object = product
    pgo.save!
    puts "Stripe product was created for the #{class_name} \##{id}"
  end
end
