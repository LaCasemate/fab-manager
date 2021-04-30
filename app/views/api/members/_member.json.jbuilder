# frozen_string_literal: true

json.extract! member, :id, :username, :email, :group_id
json.role member.roles.first.name
json.name member.profile.full_name
json.need_completion member.need_completion?
json.ip_address member.current_sign_in_ip.to_s

json.profile do
  json.id member.profile.id
  if member.profile.user_avatar
    json.user_avatar do
      json.id member.profile.user_avatar.id
      json.attachment_url "#{member.profile.user_avatar.attachment_url}?#{member.profile.user_avatar.updated_at.to_i}"
    end
  end
  json.first_name member.profile.first_name
  json.last_name member.profile.last_name
  json.interest member.profile.interest
  json.software_mastered member.profile.software_mastered
  json.phone member.profile.phone
  json.website member.profile.website
  json.job member.profile.job
  json.extract! member.profile, :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr
  json.tours member.profile.tours&.split || []
end

json.invoicing_profile do
  json.id member.invoicing_profile.id
  if member.invoicing_profile.address
    json.address do
      json.id member.invoicing_profile.address.id
      json.address member.invoicing_profile.address.address
    end
  end

  if member.invoicing_profile.organization
    json.organization do
      json.id member.invoicing_profile.organization.id
      json.name member.invoicing_profile.organization.name
      if member.invoicing_profile.organization.address
        json.address do
          json.id member.invoicing_profile.organization.address.id
          json.address member.invoicing_profile.organization.address.address
        end
      end
    end
  end
end

json.statistic_profile do
  json.id member.statistic_profile.id
  json.gender member.statistic_profile.gender.to_s
  json.birthday member.statistic_profile&.birthday&.to_date&.iso8601
end

if member.subscribed_plan
  json.subscribed_plan do
    json.partial! 'api/shared/plan', plan: member.subscribed_plan
  end
end

if member.subscription
  json.subscription do
    json.id member.subscription.id
    json.expired_at member.subscription.expired_at.iso8601
    json.canceled_at member.subscription.canceled_at.iso8601 if member.subscription.canceled_at
    json.plan do # TODO, refactor: duplicates subscribed_plan
      json.id member.subscription.plan.id
      json.base_name member.subscription.plan.base_name
      json.name member.subscription.plan.name
      json.interval member.subscription.plan.interval
      json.interval_count member.subscription.plan.interval_count
      json.amount member.subscription.plan.amount ? (member.subscription.plan.amount / 100.0) : 0
    end
  end
end
json.training_credits member.training_credits do |tc|
  json.training_id tc.creditable_id
end
json.machine_credits member.machine_credits do |mc|
  json.machine_id mc.creditable_id
  json.hours_used mc.users_credits.find_by(user_id: member.id).hours_used
end
# TODO, missing space_credits?
json.last_sign_in_at member.last_sign_in_at.iso8601 if member.last_sign_in_at
