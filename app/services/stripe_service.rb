# frozen_string_literal: true

# Helpers and utilities for interactions with the Stripe payment gateway
class StripeService
  class << self

    # Create the provided PaymentSchedule on Stripe, using the Subscription API
    def create_stripe_subscription(payment_schedule_id, reservable_stp_id)
      payment_schedule = PaymentSchedule.find(payment_schedule_id)
      first_item = payment_schedule.ordered_items.first

      # subscription (recurring price)
      price = create_price(first_item.details['recurring'],
                           payment_schedule.scheduled.plan.stp_product_id,
                           nil, monthly: true)
      # other items (not recurring)
      items = subscription_invoice_items(payment_schedule, first_item, reservable_stp_id)

      stp_subscription = Stripe::Subscription.create({
                                                       customer: payment_schedule.invoicing_profile.user.stp_customer_id,
                                                       cancel_at: payment_schedule.scheduled.expiration_date.to_i,
                                                       promotion_code: payment_schedule.coupon&.code,
                                                       add_invoice_items: items,
                                                       items: [
                                                         { price: price[:id] }
                                                       ]
                                                     }, { api_key: Setting.get('stripe_secret_key') })
      payment_schedule.update_attributes(stp_subscription_id: stp_subscription.id)
    end

    private

    def subscription_invoice_items(payment_schedule, first_item, reservable_stp_id)
      second_item = payment_schedule.ordered_items[1]

      items = []
      if first_item.amount != second_item.amount
        unless first_item.details['adjustment']&.zero?
          # adjustment: when dividing the price of the plan / months, sometimes it forces us to round the amount per month.
          # The difference is invoiced here
          p1 = create_price(first_item.details['adjustment'],
                            payment_schedule.scheduled.plan.stp_product_id,
                            "Price adjustment for payment schedule #{payment_schedule.id}")
          items.push(price: p1[:id])
        end
        unless first_item.details['other_items']&.zero?
          # when taking a subscription at the same time of a reservation (space, machine or training), the amount of the
          # reservation is invoiced here.
          p2 = create_price(first_item.details['other_items'],
                            reservable_stp_id,
                            "Reservations for payment schedule #{payment_schedule.id}")
          items.push(price: p2[:id])
        end
      end

      items
    end

    def create_price(amount, stp_product_id, name, monthly: false)
      params = {
        unit_amount: amount,
        currency: Setting.get('stripe_currency'),
        product: stp_product_id,
        nickname: name
      }
      params[:recurring] = { interval: 'month', interval_count: 1 } if monthly

      Stripe::Price.create(params, { api_key: Setting.get('stripe_secret_key') })
    end
  end
end
