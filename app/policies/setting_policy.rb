# frozen_string_literal: true

# Check the access policies for API::SettingsController
class SettingPolicy < ApplicationPolicy
  # Defines the scope of the settings index, depending on the role of the current user
  class Scope < Scope
    def resolve
      if user.nil? || (user && !user.admin?)
        scope.where.not(name: SettingPolicy.public_blacklist)
      else
        scope
      end
    end
  end

  %w[update bulk_update reset].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end

  def show?
    user&.admin? || SettingPolicy.public_whitelist.include?(record.name)
  end

  def test_present?
    user&.admin? || SettingPolicy.public_whitelist.concat(%w[openlab_app_secret stripe_secret_key]).include?(record.name)
  end

  ##
  # Every settings that anyone can read. The other settings are restricted for admins.
  # This list must be manually updated if a new setting should be world-readable
  ##
  def self.public_whitelist
    %w[about_title about_body about_contacts privacy_body privacy_dpo twitter_name home_blogpost machine_explications_alert
       training_explications_alert training_information_message subscription_explications_alert booking_window_start
       booking_window_end booking_slot_duration booking_move_enable booking_move_delay booking_cancel_enable booking_cancel_delay
       fablab_name name_genre event_explications_alert space_explications_alert link_name home_content phone_required
       tracking_id book_overlapping_slots slot_duration events_in_calendar spaces_module plans_module invoicing_module
       recaptcha_site_key feature_tour_display disqus_shortname allowed_cad_extensions openlab_app_id openlab_default
       online_payment_module stripe_public_key confirmation_required wallet_module trainings_module address_required
       payment_gateway payzen_endpoint payzen_public_key]
  end

  ##
  # Every settings that only admins can read.
  # This blacklist is automatically generated from the public_whitelist above.
  ##
  def self.public_blacklist
    Setting.validators.detect { |v| v.class == ActiveModel::Validations::InclusionValidator && v.attributes.include?(:name) }
           .options[:in] - SettingPolicy.public_whitelist
  end
end
