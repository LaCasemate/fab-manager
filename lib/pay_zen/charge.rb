# frozen_string_literal: true

require 'pay_zen/client'

# Charge/* endpoints of the PayZen REST API
class PayZen::Charge < PayZen::Client
  def initialize(base_url: nil, username: nil, password: nil)
    super(base_url: base_url, username: username, password: password)
  end

  ##
  # @see https://payzen.io/fr-FR/rest/V4.0/api/playground/Charge/SDKTest/
  ##
  def sdk_test(value)
    post('/Charge/SDKTest', value: value)
  end

  ##
  # @see https://payzen.io/en-EN/rest/V4.0/api/playground/Charge/CreatePayment/
  ##
  def create_payment(amount: 0,
                     currency: Setting.get('payzen_currency'),
                     order_id: nil,
                     form_action: 'PAYMENT',
                     contrib: "fab-manager #{Version.current}",
                     customer: nil)
    post('/Charge/CreatePayment',
         amount: amount,
         currency: currency,
         orderId: order_id,
         formAction: form_action,
         contrib: contrib,
         customer: customer)
  end

  ##
  # @see https://payzen.io/en-EN/rest/V4.0/api/playground/Charge/CreateToken/
  ##
  def create_token(currency: Setting.get('payzen_currency'),
                   order_id: nil,
                   contrib: "fab-manager #{Version.current}",
                   customer: nil)
    post('/Charge/CreateToken',
         currency: currency,
         orderId: order_id,
         contrib: contrib,
         customer: customer)
  end

  ##
  # @see https://payzen.io/fr-FR/rest/V4.0/api/playground/Charge/CreateSubscription
  ##
  def create_subscription(amount: 0,
                          currency: Setting.get('payzen_currency'),
                          effect_date: DateTime.current.to_s,
                          payment_method_token: nil,
                          rrule: nil,
                          order_id: nil,
                          initial_amount: nil,
                          initial_amount_number: nil)
    post('Charge/CreateSubscription,',
         amount: amount,
         currency: currency,
         effectDate: effect_date,
         paymentMethodToken: payment_method_token,
         rrule: rrule,
         orderId: order_id,
         initialAmount: initial_amount,
         initialAmountNumber: initial_amount_number)
  end
end

