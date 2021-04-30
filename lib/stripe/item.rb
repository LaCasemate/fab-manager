# frozen_string_literal: true

require 'payment/item'

# Stripe payement gateway
module Stripe; end

## generic wrapper around Stripe classes
class Stripe::Item < Payment::Item
  attr_accessor :id

  def retrieve(id = nil)
    @id ||= id
    klass.constantize.retrieve(@id, api_key: Setting.get('stripe_secret_key'))
  end

  def payment_mean?
    klass == 'Stripe::SetupIntent'
  end
end
