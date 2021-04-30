# frozen_string_literal: true

json.extract! subscription, :id, :plan_id
json.expired_at subscription.expired_at.iso8601
json.canceled_at subscription.canceled_at.iso8601 if subscription.canceled_at
json.plan do
  json.partial! 'api/shared/plan', plan: subscription.plan
end
