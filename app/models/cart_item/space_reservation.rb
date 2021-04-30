# frozen_string_literal: true

# A space reservation added to the shopping cart
class CartItem::SpaceReservation < CartItem::Reservation
  # @param plan {Plan} a subscription bought at the same time of the reservation OR an already running subscription
  # @param new_subscription {Boolean} true is new subscription is being bought at the same time of the reservation
  def initialize(customer, operator, space, slots, plan: nil, new_subscription: false)
    raise TypeError unless space.is_a? Space

    super(customer, operator, space, slots)
    @plan = plan
    @new_subscription = new_subscription
  end

  protected

  def credits
    return 0 if @plan.nil?

    space_credit = @plan.space_credits.find { |credit| credit.creditable_id == @reservable.id }
    credits_hours(space_credit, @new_subscription)
  end
end
