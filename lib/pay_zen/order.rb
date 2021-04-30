# frozen_string_literal: true

require 'pay_zen/client'

# Order/* endpoints of the PayZen REST API
class PayZen::Order < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/en-EN/rest/V4.0/api/playground/Order/Get/
  ##
  def get(order_id, operation_type: nil)
    post('/Order/Get/', orderId: order_id, operationType: operation_type)
  end
end
