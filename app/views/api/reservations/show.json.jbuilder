# frozen_string_literal: true

json.id @reservation.id
json.user_id @reservation.statistic_profile.user_id
json.user do
  json.id @reservation.user.id
  if @reservation.user.subscribed_plan
    json.subscribed_plan do
      json.partial! 'api/shared/plan', plan: @reservation.user.subscribed_plan
    end
  end
  json.training_credits @reservation.user.training_credits do |tc|
    json.training_id tc.creditable_id
  end
  json.machine_credits @reservation.user.machine_credits do |mc|
    json.machine_id mc.creditable_id
    json.hours_used mc.users_credits.find_by(user_id: @reservation.statistic_profile.user_id).hours_used
  end
end
json.message @reservation.message
json.slots_attributes @reservation.slots do |s|
  json.id s.id
  json.start_at s.start_at.iso8601
  json.end_at s.end_at.iso8601
  json.is_reserved true
end
json.reservable do
  json.id @reservation.reservable.id
  json.name @reservation.reservable.name
end
json.nb_reserve_places @reservation.nb_reserve_places
json.tickets @reservation.tickets do |t|
  json.extract! t, :booked, :created_at
  json.event_price_category do
    json.extract! t.event_price_category, :id, :price_category_id
    json.price_category do
      json.extract! t.event_price_category.price_category, :id, :name
    end
  end
end
json.total_booked_seats @reservation.total_booked_seats
json.created_at @reservation.created_at.iso8601
