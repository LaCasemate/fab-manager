# frozen_string_literal: true

# Coupon is a textual code associated with a discount rate or an amount of discount
class Coupon < ApplicationRecord
  has_many :invoices
  has_many :payment_schedule

  after_create :create_gateway_coupon
  after_commit :delete_gateway_coupon, on: [:destroy]

  validates :name, presence: true
  validates :code, presence: true
  validates :code, format: { with: /\A[A-Z0-9\-]+\z/, message: 'only caps letters, numbers, and dashes' }
  validates :code, uniqueness: true
  validates :validity_per_user, presence: true
  validates :validity_per_user, inclusion: { in: %w[once forever] }
  validates_with CouponDiscountValidator
  validates_with CouponExpirationValidator

  scope :disabled, -> { where(active: false) }
  scope :expired, -> { where('valid_until IS NOT NULL AND valid_until < ?', DateTime.current) }
  scope :sold_out, lambda {
    joins(:invoices).select('coupons.*, COUNT(invoices.id) as invoices_count').group('coupons.id')
                    .where.not(max_usages: nil).having('COUNT(invoices.id) >= coupons.max_usages')
  }
  scope :active, lambda {
    joins('LEFT OUTER JOIN invoices ON invoices.coupon_id = coupons.id')
      .select('coupons.*, COUNT(invoices.id) as invoices_count')
      .group('coupons.id')
      .where('active = true AND (valid_until IS NULL OR valid_until >= ?)', DateTime.current)
      .having('COUNT(invoices.id) < coupons.max_usages OR coupons.max_usages IS NULL')
  }

  def safe_destroy
    if usages.zero?
      destroy
    else
      false
    end
  end

  def usages
    invoices.count
  end

  ##
  # Check the status of the current coupon. The coupon:
  # - may have been disabled by an admin,
  # - may has expired because the validity date has been reached,
  # - may have been used the maximum number of times it was allowed
  # - may have already been used by the provided user, if the coupon is configured to allow only one use per user,
  # - may exceed the current cart's total amount, if the coupon is configured to discount an amount (and not a percentage)
  # - may be available for use
  # @param [user_id] {Number} if provided and if the current coupon's validity_per_user == 'once', check that the coupon
  # was already used by the provided user
  # @param [amount] {Number} if provided and if the current coupon's type == 'amont_off' check that the coupon
  # does not exceed the cart total price
  # @return {String} status identifier
  ##
  def status(user_id = nil, amount = nil)
    if !active?
      'disabled'
    elsif !valid_until.nil? && valid_until.at_end_of_day < DateTime.current
      'expired'
    elsif !max_usages.nil? && invoices.count >= max_usages
      'sold_out'
    elsif !user_id.nil? && validity_per_user == 'once' && users_ids.include?(user_id.to_i)
      'already_used'
    elsif !amount.nil? && type == 'amount_off' && amount_off > amount.to_f
      'amount_exceeded'
    else
      'active'
    end
  end

  def type
    if amount_off.nil? && !percent_off.nil?
      'percent_off'
    elsif percent_off.nil? && !amount_off.nil?
      'amount_off'
    end
  end

  def users
    invoices.map(&:user)
  end

  def users_ids
    users.map(&:id)
  end

  def send_to(user_id)
    NotificationCenter.call type: 'notify_member_about_coupon',
                            receiver: User.find(user_id),
                            attached_object: self
  end

  private

  def create_gateway_coupon
    PaymentGatewayService.create_coupon(id)
  end

  def delete_gateway_coupon
    PaymentGatewayService.delete_coupon(id)
  end

end
