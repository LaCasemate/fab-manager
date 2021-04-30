# frozen_string_literal: true

# Stores data about a shopping data
class ShoppingCart
  attr_accessor :customer, :payment_method, :items, :coupon, :payment_schedule

  # @param items {Array<CartItem::BaseItem>}
  # @param coupon {CartItem::Coupon}
  # @param payment_schedule {CartItem::PaymentSchedule}
  # @param customer {User}
  def initialize(customer, coupon, payment_schedule, payment_method = '', items: [])
    raise TypeError unless customer.is_a? User

    @customer = customer
    @payment_method = payment_method
    @items = items
    @coupon = coupon
    @payment_schedule = payment_schedule
  end

  # compute the price details of the current shopping cart
  def total
    total_amount = 0
    all_elements = { slots: [] }

    @items.map(&:price).each do |price|
      total_amount += price[:amount]
      all_elements = all_elements.merge(price[:elements]) do |_key, old_val, new_val|
        old_val | new_val
      end
    end

    coupon_info = @coupon.price(total_amount)
    schedule_info = @payment_schedule.schedule(coupon_info[:total_with_coupon], coupon_info[:total_without_coupon])

    # return result
    {
      elements: all_elements,
      total: schedule_info[:total].to_i,
      before_coupon: coupon_info[:total_without_coupon].to_i,
      coupon: @coupon.coupon,
      schedule: schedule_info[:schedule]
    }
  end
end
