# frozen_string_literal: true

# Stripe payement gateway
module Stripe; end

## Provides various methods around the Stripe payment gateway
class Stripe::Helper
  class << self
    ## Is the Stripe gateway enabled?
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'stripe'

      res = true
      %w[stripe_public_key stripe_secret_key stripe_currency].each do |pz_setting|
        res = false unless Setting.get(pz_setting).present?
      end
      res
    end
  end
end
