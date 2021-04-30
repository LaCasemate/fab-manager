# frozen_string_literal: true

json.extract! payment_schedule, :id, :reference, :created_at, :payment_method
json.total payment_schedule.total / 100.00
json.chained_footprint payment_schedule.check_footprint
json.user do
  json.id payment_schedule.invoicing_profile&.user&.id
  json.name payment_schedule.invoicing_profile.full_name
end
if payment_schedule.operator_profile
  json.operator do
    json.id payment_schedule.operator_profile.user_id
    json.extract! payment_schedule.operator_profile, :first_name, :last_name
  end
end
json.items payment_schedule.payment_schedule_items do |item|
  json.extract! item, :id, :due_date, :state, :invoice_id, :payment_method
  json.amount item.amount / 100.00
  json.client_secret item.payment_intent.client_secret if item.payment_gateway_object && item.state == 'requires_action'
end
