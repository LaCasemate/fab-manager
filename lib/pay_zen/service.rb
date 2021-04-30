# frozen_string_literal: true

require 'payment/service'
require 'pay_zen/charge'
require 'pay_zen/order'

# PayZen payement gateway
module PayZen; end

## create remote objects on PayZen
class PayZen::Service < Payment::Service
  def create_subscription(payment_schedule, order_id)
    first_item = payment_schedule.ordered_items.first

    order = PayZen::Order.new.get(order_id: order_id, operation_type: 'VERIFICATION')
    client = PayZen::Charge.new

    params = {
      amount: first_item.details['recurring'].to_i,
      effect_date: first_item.due_date.to_s,
      payment_method_token: order['answer']['transactions'].first['paymentMethodToken'],
      rrule: rrule(payment_schedule),
      order_id: order_id
    }
    unless first_item.details['adjustment']&.zero?
      params[:initial_amount] = first_item.amount
      params[:initial_amount_number] = 1
    end
    client.create_subscription(params)
  end

  private

  def rrule(payment_schedule)
    count = payment_schedule.payment_schedule_items.count
    last = payment_schedule.ordered_items.last.due_date.strftime('%Y%m%d')
    "RRULE:FREQ=MONTHLY;COUNT=#{count};UNTIL=#{last}"
  end
end
