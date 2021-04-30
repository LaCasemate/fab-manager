json.array!(@invoices) do |invoice|
  json.extract! invoice, :id, :created_at, :reference, :invoiced_type, :user_id, :avoir_date
  json.total (invoice.total / 100.00)

  json.name invoice.user.profile.full_name
  json.has_avoir invoice.refunded?
  json.is_avoir invoice.is_a?(Avoir)
  json.is_subscription_invoice invoice.subscription_invoice?
  json.stripe invoice.paid_by_card?
  json.date invoice.is_a?(Avoir) ? invoice.avoir_date : invoice.created_at
  json.prevent_refund invoice.prevent_refund?
end
