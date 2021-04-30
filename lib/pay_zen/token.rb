# frozen_string_literal: true

require 'pay_zen/client'

# Token/* endpoints of the PayZen REST API
class PayZen::Token < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/en-EN/rest/V4.0/api/playground/Token/Get/
  ##
  def get(payment_method_token)
    post('/Token/Get/', paymentMethodToken: payment_method_token)
  end
end
