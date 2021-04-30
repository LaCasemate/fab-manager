# frozen_string_literal: true

# Provides helper methods for Reservation actions
class Reservations::Reserve
  attr_accessor :user_id, :operator_profile_id

  def initialize(user_id, operator_profile_id)
    @user_id = user_id
    @operator_profile_id = operator_profile_id
  end

  ##
  # Confirm the payment of the given reservation, generate the associated documents and save the record into
  # the database.
  ##
  def pay_and_save(reservation, payment_details: nil, payment_id: nil, payment_type: nil, schedule: false, payment_method: nil)
    user = User.find(user_id)
    reservation.statistic_profile_id = StatisticProfile.find_by(user_id: user_id).id

    ActiveRecord::Base.transaction do
      reservation.pre_check
      payment = if schedule
                  generate_schedule(reservation: reservation,
                                    total: payment_details[:before_coupon],
                                    operator_profile_id: operator_profile_id,
                                    user: user,
                                    payment_method: payment_method,
                                    coupon: payment_details[:coupon],
                                    payment_id: payment_id,
                                    payment_type: payment_type)
                else
                  generate_invoice(reservation,
                                   operator_profile_id,
                                   payment_details,
                                   payment_id: payment_id,
                                   payment_type: payment_type,
                                   payment_method: payment_method)
                end
      WalletService.debit_user_wallet(payment, user, reservation)
      reservation.save
      reservation.post_save
      payment.save
      payment.post_save(payment_id)
    end
    true
  end

  private

  ##
  # Generate the invoice for the given reservation+subscription
  ##
  def generate_schedule(reservation: nil, total: nil, operator_profile_id: nil, user: nil, payment_method: nil, coupon: nil,
                        payment_id: nil, payment_type: nil)
    operator = InvoicingProfile.find(operator_profile_id)&.user

    PaymentScheduleService.new.create(
      nil,
      total,
      coupon: coupon,
      operator: operator,
      payment_method: payment_method,
      user: user,
      reservation: reservation,
      payment_id: payment_id,
      payment_type: payment_type
    )
  end

  ##
  # Generate the invoice for the given reservation
  ##
  def generate_invoice(reservation, operator_profile_id, payment_details, payment_id: nil, payment_type: nil, payment_method: nil)
    InvoicesService.create(
      payment_details,
      operator_profile_id,
      reservation: reservation,
      payment_id: payment_id,
      payment_type: payment_type,
      payment_method: payment_method
    )
  end

end
