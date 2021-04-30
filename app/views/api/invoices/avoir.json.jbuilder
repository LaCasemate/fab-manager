json.extract! @avoir, :id, :created_at, :reference, :invoiced_type, :avoir_date, :payment_method, :invoice_id
json.user_id @avoir.invoicing_profile.user_id
json.total @avoir.total / 100.00
json.name @avoir.user.profile.full_name
json.has_avoir false
json.is_avoir true
json.date @avoir.avoir_date
json.chained_footprint @avoir.check_footprint
json.items @avoir.invoice_items do |item|
  json.id item.id
  json.amount item.amount / 100.0
  json.description item.description
  json.invoice_item_id item.invoice_item_id
end
