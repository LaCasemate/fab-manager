# frozen_string_literal: true

json.extract! invoiced, :created_at, :expiration_date, :canceled_at
if invoiced.payment_gateway_object
  json.payment_gateway_object do
    json.id invoiced.payment_gateway_object.gateway_object_id
    json.type invoiced.payment_gateway_object.gateway_object_type
  end
end
json.plan do
  json.extract! invoiced.plan, :id, :base_name, :interval, :interval_count, :stp_plan_id, :is_rolling
  json.group do
    json.extract! invoiced.plan.group, :id, :name
  end
end
