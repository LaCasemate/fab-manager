# frozen_string_literal: true

# Check the access policies for API::PayzenController
class PayzenPolicy < ApplicationPolicy
  def sdk_test?
    user.admin?
  end
end
