# frozen_string_literal: true

# A payment schedule applied to plan in the shopping cart
class CartItem::PaymentSchedule
  def initialize(plan, coupon, requested)
    raise TypeError unless coupon.is_a? CartItem::Coupon

    @plan = plan
    @coupon = coupon
    @requested = requested
  end

  def schedule(total, total_without_coupon)
    schedule = if @requested && @plan&.monthly_payment
                 PaymentScheduleService.new.compute(@plan, total_without_coupon, coupon: @coupon.coupon)
               else
                 nil
               end

    total_amount = if schedule
                     schedule[:items][0].amount
                   else
                     total
                   end

    { schedule: schedule, total: total_amount }
  end
end
