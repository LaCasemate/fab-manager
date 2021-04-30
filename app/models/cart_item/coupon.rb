# frozen_string_literal: true

# A discount coupon applied to the whole shopping cart
class CartItem::Coupon

  # @param coupon {String|Coupon} may be nil or empty string if no coupons are applied
  def initialize(customer, operator, coupon)
    @customer = customer
    @operator = operator
    @coupon = coupon
  end

  def coupon
    cs = CouponService.new
    cs.validate(@coupon, @customer.id)
  end

  def price(cart_total = 0)
    cs = CouponService.new
    new_total = cs.apply(cart_total, coupon)

    amount = new_total - cart_total

    { amount: amount, total_with_coupon: new_total, total_without_coupon: cart_total }
  end
end
