# frozen_string_literal: true

# Saves references to remote objects, in the payment gateway database
class CreatePaymentGatewayObjects < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_gateway_objects do |t|
      t.string :gateway_object_id
      t.string :gateway_object_type
      t.references :item, polymorphic: true
    end
  end
end
