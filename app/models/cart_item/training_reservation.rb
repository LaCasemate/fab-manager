# frozen_string_literal: true

# A training reservation added to the shopping cart
class CartItem::TrainingReservation < CartItem::Reservation
  # @param plan {Plan} a subscription bought at the same time of the reservation OR an already running subscription
  # @param new_subscription {Boolean} true is new subscription is being bought at the same time of the reservation
  def initialize(customer, operator, training, slots, plan: nil, new_subscription: false)
    raise TypeError unless training.is_a? Training

    super(customer, operator, training, slots)
    @plan = plan
    @new_subscription = new_subscription
  end

  def price
    base_amount = @reservable.amount_by_group(@customer.group_id).amount
    is_privileged = @operator.admin? || (@operator.manager? && @operator.id != @customer.id)

    elements = { slots: [] }
    amount = 0

    hours_available = credits
    @slots.each do |slot|
      amount += get_slot_price(base_amount,
                               slot,
                               is_privileged,
                               elements: elements,
                               has_credits: (@customer.training_credits.size < hours_available),
                               is_division: false)
    end

    { elements: elements, amount: amount }
  end

  protected

  def credits
    return 0 if @plan.nil?

    is_creditable = @plan.training_credits.select { |credit| credit.creditable_id == @reservable.id }.any?
    is_creditable ? @plan.training_credit_nb : 0
  end
end
