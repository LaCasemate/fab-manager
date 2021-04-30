# frozen_string_literal: true

# Store customized price for various items (Machine, Space), depending on the group and on the plan
class Price < ApplicationRecord
  belongs_to :group
  belongs_to :plan
  belongs_to :priceable, polymorphic: true

  validates :priceable, :group_id, :amount, presence: true
  validates :priceable_id, uniqueness: { scope: %i[priceable_type plan_id group_id] }
end
