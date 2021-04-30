# frozen_string_literal: true

json.invoices @invoices do |invoice|
  json.extract! invoice, :id, :invoiced_id, :user_id, :invoiced_type, :reference, :total, :type, :description
  if invoice.payment_gateway_object
    json.payment_gateway_object do
      json.id invoice.payment_gateway_object.gateway_object_id
      json.type invoice.payment_gateway_object.gateway_object_type
    end
  end

  json.invoice_url download_open_api_v1_invoice_path(invoice)
  json.invoiced do
    json.created_at invoice.invoiced.created_at
  end
end
