# frozen_string_literal: true

# This table will save the user's profile data needed for legal accounting (invoices, wallet, etc.)
# Legal accounting must be kept for 10 years but GDPR requires that an user can delete his account at any time.
# The data will be kept even if the user is deleted, but it will be unlinked from the user's account.
class InvoicingProfile < ApplicationRecord
  belongs_to :user
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true
  has_one :organization, dependent: :destroy
  accepts_nested_attributes_for :organization, allow_destroy: false
  has_many :invoices, dependent: :destroy
  has_many :payment_schedules, dependent: :destroy

  has_one :wallet, dependent: :destroy
  has_many :wallet_transactions, dependent: :destroy

  has_many :history_values, dependent: :nullify

  has_many :operated_invoices, foreign_key: :operator_profile_id, class_name: 'Invoice', dependent: :nullify
  has_many :operated_payment_schedules, foreign_key: :operator_profile_id, class_name: 'PaymentSchedule', dependent: :nullify

  validates :address, presence: true, if: -> { Setting.get('address_required') }

  def full_name
    # if first_name or last_name is nil, the empty string will be used as a temporary replacement
    (first_name || '').humanize.titleize + ' ' + (last_name || '').humanize.titleize
  end
end
