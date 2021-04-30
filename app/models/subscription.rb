# frozen_string_literal: true

# Subscription is an active or archived subscription of an User to a Plan
class Subscription < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  belongs_to :plan
  belongs_to :statistic_profile

  has_one :payment_schedule, as: :scheduled, dependent: :destroy
  has_one :payment_gateway_object, as: :item
  has_many :invoices, as: :invoiced, dependent: :destroy
  has_many :offer_days, dependent: :destroy

  validates_presence_of :plan_id
  validates_with SubscriptionGroupValidator

  # creation
  after_save :notify_member_subscribed_plan
  after_save :notify_admin_subscribed_plan
  after_save :notify_partner_subscribed_plan, if: :of_partner_plan?

  ##
  # Set the inner properties of the subscription, init the user's credits and save the subscription into the DB
  # @return {boolean} true, if the operation succeeded
  ##
  def init_save
    return false unless valid?

    set_expiration_date
    return false unless save

    UsersCredits::Manager.new(user: user).reset_credits
    true
  end

  def generate_and_save_invoice(operator_profile_id)
    generate_invoice(operator_profile_id).save
  end

  def expire(time)
    if !expired?
      update_columns(expiration_date: time, canceled_at: time)
      notify_admin_subscription_canceled
      notify_member_subscription_canceled
      true
    else
      false
    end
  end

  def expired?
    expired_at <= DateTime.current
  end

  def expired_at
    last_offered = offer_days.order(:end_at).last
    return last_offered.end_at if last_offered

    expiration_date
  end

  def free_extend(expiration, operator_profile_id)
    return false if expiration <= expired_at

    od = offer_days.create(start_at: expired_at, end_at: expiration)
    invoice = Invoice.new(
      invoiced_id: od.id,
      invoiced_type: 'OfferDay',
      invoicing_profile: user.invoicing_profile,
      statistic_profile: user.statistic_profile,
      operator_profile_id: operator_profile_id,
      total: 0
    )
    invoice.invoice_items.push InvoiceItem.new(amount: 0, description: plan.name, subscription_id: id)
    invoice.save

    if save
      notify_subscription_extended(true)
      return true
    end
    false
  end

  def user
    statistic_profile.user
  end

  def original_payment_schedule
    # if the payment schedule was associated with this subscription, return it directly
    return payment_schedule if payment_schedule

    # if it was associated with a reservation, query payment schedule from one of its items
    PaymentScheduleItem.where("cast(details->>'subscription_id' AS int) = ?", id).first&.payment_schedule
  end

  private

  def notify_member_subscribed_plan
    NotificationCenter.call type: 'notify_member_subscribed_plan',
                            receiver: user,
                            attached_object: self
  end

  def notify_admin_subscribed_plan
    NotificationCenter.call type: 'notify_admin_subscribed_plan',
                            receiver: User.admins,
                            attached_object: self
  end

  def notify_admin_subscription_canceled
    NotificationCenter.call type: 'notify_admin_subscription_canceled',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end

  def notify_member_subscription_canceled
    NotificationCenter.call type: 'notify_member_subscription_canceled',
                            receiver: user,
                            attached_object: self
  end

  def notify_partner_subscribed_plan
    NotificationCenter.call type: 'notify_partner_subscribed_plan',
                            receiver: plan.partners,
                            attached_object: self
  end

  def notify_subscription_extended(free_days)
    meta_data = {}
    meta_data[:free_days] = true if free_days
    NotificationCenter.call type: :notify_member_subscription_extended,
                            receiver: user,
                            attached_object: self,
                            meta_data: meta_data

    NotificationCenter.call type: :notify_admin_subscription_extended,
                            receiver: User.admins_and_managers,
                            attached_object: self,
                            meta_data: meta_data
  end

  def set_expiration_date
    start_at = DateTime.current.in_time_zone
    self.expiration_date = start_at + plan.duration
  end

  def of_partner_plan?
    plan.is_a?(PartnerPlan)
  end
end
