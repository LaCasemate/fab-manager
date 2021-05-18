# frozen_string_literal: true

json.extract! event, :id, :title, :description
json.event_image event.event_image.attachment_url if event.event_image
json.event_files_attributes event.event_files do |f|
  json.id f.id
  json.attachment f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.category_id event.category_id
if event.category
  json.category do
    json.id event.category.id
    json.name event.category.name
    json.slug event.category.slug
  end
end
json.event_theme_ids event.event_theme_ids
json.event_themes event.event_themes do |e|
  json.name e.name
end
json.age_range_id event.age_range_id
if event.age_range
  json.age_range do
    json.name event.age_range.name
  end
end
json.start_date event.availability.start_at
json.start_time event.availability.start_at
json.end_date event.availability.end_at
json.end_time event.availability.end_at
json.month t('date.month_names')[event.availability.start_at.month]
json.month_id event.availability.start_at.month
json.year event.availability.start_at.year
json.all_day event.availability.start_at.hour.zero? ? 'true' : 'false'
json.availability do
  json.id event.availability.id
  json.start_at event.availability.start_at
  json.end_at event.availability.end_at
end
json.availability_id event.availability_id
json.amount (event.amount / 100.0) if event.amount
json.prices event.event_price_categories do |p_cat|
  json.id p_cat.id
  json.amount (p_cat.amount / 100.0)
  json.category do
    json.extract! p_cat.price_category, :id, :name
  end
end
json.nb_total_places event.nb_total_places
json.nb_free_places event.nb_free_places || event.nb_total_places

