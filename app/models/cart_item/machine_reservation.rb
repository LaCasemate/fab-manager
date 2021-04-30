# frozen_string_literal: true

# A machine reservation added to the shopping cart
class CartItem::MachineReservation < CartItem::Reservation
  # @param plan {Plan} a subscription bought at the same time of the reservation OR an already running subscription
  # @param new_subscription {Boolean} true is new subscription is being bought at the same time of the reservation
  def initialize(customer, operator, machine, slots, plan: nil, new_subscription: false)
    raise TypeError unless machine.is_a? Machine

    super(customer, operator, machine, slots)
    @plan = plan
    @new_subscription = new_subscription
  end

  protected

  def credits
    return 0 if @plan.nil?

    machine_credit = @plan.machine_credits.find { |credit| credit.creditable_id == @reservable.id }
    credits_hours(machine_credit, @new_subscription)
  end
end
