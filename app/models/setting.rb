# frozen_string_literal: true

# Setting is a configuration element of the platform. Only administrators are allowed to modify Settings
# For some settings, changing them will involve some callback actions (like rebuilding the stylesheets if the theme color Setting is changed).
# A full history of the previous values is kept in database with the date and the author of the change
# after_update callback is handled by SettingService
class Setting < ApplicationRecord
  has_many :history_values
  # The following list contains all the settings that can be customized from the Fab-manager's UI.
  # A few of them that are system settings, that should not be updated manually (uuid, origin).
  validates :name, inclusion:
                    { in: %w[about_title
                             about_body
                             about_contacts
                             privacy_draft
                             privacy_body
                             privacy_dpo
                             twitter_name
                             home_blogpost
                             machine_explications_alert
                             training_explications_alert
                             training_information_message
                             subscription_explications_alert
                             invoice_logo
                             invoice_reference
                             invoice_code-active
                             invoice_code-value
                             invoice_order-nb
                             invoice_VAT-active
                             invoice_VAT-rate
                             invoice_text
                             invoice_legals
                             booking_window_start
                             booking_window_end
                             booking_slot_duration
                             booking_move_enable
                             booking_move_delay
                             booking_cancel_enable
                             booking_cancel_delay
                             main_color
                             secondary_color
                             fablab_name
                             name_genre
                             reminder_enable
                             reminder_delay
                             event_explications_alert
                             space_explications_alert
                             visibility_yearly
                             visibility_others
                             display_name_enable
                             machines_sort_by
                             accounting_journal_code
                             accounting_card_client_code
                             accounting_card_client_label
                             accounting_wallet_client_code
                             accounting_wallet_client_label
                             accounting_other_client_code
                             accounting_other_client_label
                             accounting_wallet_code
                             accounting_wallet_label
                             accounting_VAT_code
                             accounting_VAT_label
                             accounting_subscription_code
                             accounting_subscription_label
                             accounting_Machine_code
                             accounting_Machine_label
                             accounting_Training_code
                             accounting_Training_label
                             accounting_Event_code
                             accounting_Event_label
                             accounting_Space_code
                             accounting_Space_label
                             hub_last_version
                             hub_public_key
                             fab_analytics
                             link_name
                             home_content
                             home_css
                             origin
                             uuid
                             phone_required
                             tracking_id
                             book_overlapping_slots
                             slot_duration
                             events_in_calendar
                             spaces_module
                             plans_module
                             invoicing_module
                             facebook_app_id
                             twitter_analytics
                             recaptcha_site_key
                             recaptcha_secret_key
                             feature_tour_display
                             email_from
                             disqus_shortname
                             allowed_cad_extensions
                             allowed_cad_mime_types
                             openlab_app_id
                             openlab_app_secret
                             openlab_default
                             online_payment_module
                             stripe_public_key
                             stripe_secret_key
                             stripe_currency
                             invoice_prefix
                             confirmation_required
                             wallet_module
                             statistics_module
                             upcoming_events_shown
                             payment_schedule_prefix
                             trainings_module
                             address_required
                             accounting_Error_code
                             accounting_Error_label
                             address_required
                             payment_gateway
                             payzen_username
                             payzen_password
                             payzen_endpoint
                             payzen_public_key
                             payzen_hmac
                             payzen_currency] }
  # WARNING: when adding a new key, you may also want to add it in app/policies/setting_policy.rb#public_whitelist

  def value
    last_value = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(1).first
    last_value&.value
  end

  def value_at(date)
    val = history_values.order(HistoryValue.arel_table['created_at'].desc).where('created_at <= ?', date).limit(1).first
    val&.value
  end

  def first_update
    first_value = history_values.order(HistoryValue.arel_table['created_at'].asc).limit(1).first
    first_value&.created_at
  end

  def first_value
    first_value = history_values.order(HistoryValue.arel_table['created_at'].asc).limit(1).first
    first_value&.value
  end

  def last_update
    last_value = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(1).first
    last_value&.created_at
  end

  def previous_update
    previous_value = history_values.order(HistoryValue.arel_table['created_at'].desc).limit(2).last
    previous_value&.created_at
  end

  def value=(val)
    admin = User.admins.first
    save && history_values.create(invoicing_profile: admin.invoicing_profile, value: val)
  end

  ##
  # Return the value of the requested setting, if any.
  # Usage: Setting.get('my_setting')
  # @return {String|Boolean}
  ##
  def self.get(name)
    res = find_by(name: name)&.value

    # handle boolean values
    return true if res == 'true'
    return false if res == 'false'

    res
  end

  ##
  # Create or update the provided setting with the given value
  # Usage: Setting.set('my_setting', true)
  # Optionally (but recommended when possible), the user updating the value can be provided as the third parameter
  # Eg.: Setting.set('my_setting', true, User.find_by(slug: 'admin'))
  ##
  def self.set(name, value, user = User.admins.first)
    setting = find_or_initialize_by(name: name)
    setting.save && setting.history_values.create(invoicing_profile: user.invoicing_profile, value: value.to_s)
  end
end
