# frozen_string_literal: true

# Training is a course for members to acquire knowledge on a specific matter.
# Trainings are designed to be scheduled periodically through Availabilities.
# A Training can be a prerequisite before members can book a Machine.
class Training < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :training_image, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :training_image, allow_destroy: true

  has_and_belongs_to_many :machines, join_table: 'trainings_machines'

  has_many :trainings_availabilities
  has_many :availabilities, through: :trainings_availabilities, dependent: :destroy

  has_many :reservations, as: :reservable, dependent: :destroy

  # members who has validated the trainings
  has_many :statistic_profile_trainings, dependent: :destroy
  has_many :statistic_profiles, through: :statistic_profile_trainings

  has_many :trainings_pricings, dependent: :destroy

  has_many :credits, as: :creditable, dependent: :destroy
  has_many :plans, through: :credits

  has_one :payment_gateway_object, as: :item

  after_create :create_statistic_subtype
  after_create :create_trainings_pricings
  after_create :update_gateway_product
  after_update :update_gateway_product, if: :saved_change_to_name?
  after_update :update_statistic_subtype, if: :saved_change_to_name?
  after_destroy :remove_statistic_subtype

  def amount_by_group(group)
    trainings_pricings.where(group_id: group).first
  end

  def create_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'training')
    StatisticSubType.create!(statistic_types: index.first.statistic_types, key: slug, label: name)
  end

  def update_statistic_subtype
    index = StatisticIndex.where(es_type_key: 'training')
    subtype = StatisticSubType.joins(statistic_type_sub_types: :statistic_type)
                              .where(key: slug, statistic_types: { statistic_index_id: index.first.id }).first
    subtype.label = name
    subtype.save!
  end

  def remove_statistic_subtype
    subtype = StatisticSubType.where(key: slug).first
    subtype.destroy!
  end

  def destroyable?
    reservations.empty?
  end

  private

  def create_trainings_pricings
    Group.all.each do |group|
      TrainingsPricing.create(training: self, group: group, amount: 0)
    end
  end

  def update_gateway_product
    PaymentGatewayService.create_or_update_product(Training.name, id)
  end
end
