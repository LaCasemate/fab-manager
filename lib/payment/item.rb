# frozen_string_literal: true

# Payments module
module Payment; end

# Generic payment object
class Payment::Item
  attr_reader :klass

  def initialize(klass, id = nil)
    @klass = klass
    @id = id
  end

  def class
    klass
  end

  def payment_mean?
    false
  end

  def retrieve(_id = nil); end
end
