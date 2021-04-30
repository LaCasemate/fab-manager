# frozen_string_literal: true

# Payments module
module Payment; end

# Abstract class that must be implemented by each payment gateway.
# Provides methods to create remote objects on the payment gateway
class Payment::Service
  def create_subscription(_payment_schedule, _gateway_object_id); end

  def create_coupon(_coupon_id); end

  def delete_coupon(_coupon_id); end

  def create_or_update_product(_klass, _id); end
end
