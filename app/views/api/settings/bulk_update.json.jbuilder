# frozen_string_literal: true

json.settings @settings.each do |setting|
  if setting.errors.keys.count.positive?
    json.error setting.errors.full_messages
    json.id setting.id
    json.name setting.name
  else
    json.partial! 'api/settings/setting', setting: setting
  end
end
