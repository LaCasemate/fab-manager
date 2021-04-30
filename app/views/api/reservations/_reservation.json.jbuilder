# frozen_string_literal: true

json.id reservation.id
json.user_id reservation.statistic_profile.user_id
json.user_full_name reservation.user.profile.full_name
json.message reservation.message
json.slots_attributes reservation.slots do |s|
  json.id s.id
  json.start_at s.start_at.iso8601
  json.end_at s.end_at.iso8601
  json.canceled_at s.canceled_at&.iso8601
end
json.nb_reserve_places reservation.nb_reserve_places
json.tickets reservation.tickets do |t|
  json.extract! t, :booked, :created_at
  json.event_price_category do
    json.extract! t.event_price_category, :id, :price_category_id
    json.price_category do
      json.extract! t.event_price_category.price_category, :id, :name
    end
  end
end
json.total_booked_seats reservation.total_booked_seats(canceled: true)
json.created_at reservation.created_at.iso8601
json.reservable_id reservation.reservable_id
json.reservable_type reservation.reservable_type
