# frozen_string_literal: true

require 'pay_zen/client'

# Subscription/* endpoints of the PayZen REST API
class PayZen::Subscription < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/fr-FR/rest/V4.0/api/playground/Subscription/Get/
  ##
  def get(subscription_id, payment_method_token)
    post('/Subscription/Get/', subscriptionId: subscription_id, paymentMethodToken: payment_method_token)
  end
end
