# frozen_string_literal: true

# Provides methods for accessing Invoices resources and properties
class InvoicesService
  # return a paginated list of invoices, ordered by the given criterion and optionally filtered
  # @param order_key {string} any column from invoices or joined a table
  # @param direction {string} 'ASC' or 'DESC', linked to order_key
  # @param page {number} page number, used to paginate results
  # @param size {number} number of items per page
  # @param filters {Hash} allowed filters: number, customer, date.
  def self.list(order_key, direction, page, size, filters = {})
    invoices = Invoice.includes(:avoir, :invoicing_profile, invoice_items: %i[subscription invoice_item])
                      .joins(:invoicing_profile)
                      .order("#{order_key} #{direction}")
                      .page(page)
                      .per(size)


    if filters[:number].size.positive?
      invoices = invoices.where(
        'invoices.reference LIKE :search',
        search: "#{filters[:number]}%"
      )
    end
    if filters[:customer].size.positive?
      # ILIKE => PostgreSQL case-insensitive LIKE
      invoices = invoices.where(
        'invoicing_profiles.first_name ILIKE :search OR invoicing_profiles.last_name ILIKE :search',
        search: "%#{filters[:customer]}%"
      )
    end
    unless filters[:date].nil?
      invoices = invoices.where(
        "date_trunc('day', invoices.created_at) = :search",
        search: "%#{DateTime.iso8601(filters[:date]).to_time.to_date}%"
      )
    end

    invoices
  end

  # Parse the order_by clause provided by JS client from '-column' form to SQL compatible form
  # @param order_by {string} expected form: 'column' or '-column'
  def self.parse_order(order_by)
    direction = (order_by[0] == '-' ? 'DESC' : 'ASC')
    key = (order_by[0] == '-' ? order_by[1, order_by.size] : order_by)

    order_key = case key
                when 'reference'
                  'invoices.reference'
                when 'date'
                  'invoices.created_at'
                when 'total'
                  'invoices.total'
                when 'name'
                  'profiles.first_name'
                else
                  'invoices.id'
                end
    { direction: direction, order_key: order_key }
  end

  ##
  # Create an Invoice with an associated array of InvoiceItem matching the given parameters
  # @param payment_details {Hash} as generated by ShoppingCart.total
  # @param operator_profile_id {Number} ID of the user that operates the invoice generation (may be an admin, a manager or the customer himself)
  # @param reservation {Reservation} the booking reservation, if any
  # @param subscription {Subscription} the booking subscription, if any
  # @param payment_id {String} ID of the payment, a returned by the gateway, if the current invoice is paid by card
  # @param payment_method {String} the payment method used
  ##
  def self.create(payment_details, operator_profile_id, reservation: nil, subscription: nil, payment_id: nil, payment_type: nil, payment_method: nil)
    user = reservation&.user || subscription&.user
    operator = InvoicingProfile.find(operator_profile_id)&.user
    method = if payment_method
               payment_method
             else
               operator&.admin? || (operator&.manager? && operator != user) ? nil : Setting.get('payment_gateway')
             end

    pgo = payment_id.nil? ? {} : { gateway_object_id: payment_id, gateway_object_type: payment_type }
    invoice = Invoice.new(
      invoiced: subscription || reservation,
      invoicing_profile: user.invoicing_profile,
      statistic_profile: user.statistic_profile,
      operator_profile_id: operator_profile_id,
      payment_gateway_object_attributes: pgo,
      payment_method: method
    )

    InvoicesService.generate_invoice_items(invoice, payment_details, reservation: reservation, subscription: subscription)
    InvoicesService.set_total_and_coupon(invoice, user, payment_details[:coupon])
    invoice
  end

  ##
  # Generate an array of {InvoiceItem} with the elements in provided reservation, price included.
  # @param invoice {Invoice} the parent invoice
  # @param payment_details {Hash} as generated by ShoppingCart.total
  ##
  def self.generate_invoice_items(invoice, payment_details, reservation: nil, subscription: nil)
    if reservation
      case reservation.reservable
        # === Event reservation ===
      when Event
        InvoicesService.generate_event_item(invoice, reservation, payment_details)
        # === Space|Machine|Training reservation ===
      else
        InvoicesService.generate_generic_item(invoice, reservation, payment_details)
      end
    end

    return unless subscription || reservation&.plan_id

    subscription = reservation.generate_subscription if !subscription && reservation.plan_id
    InvoicesService.generate_subscription_item(invoice, subscription, payment_details)
  end

  ##
  # Generate an InvoiceItem for each slot in the given reservation and save them in invoice.invoice_items.
  # This method must be called if reservation.reservable is an Event
  ##
  def self.generate_event_item(invoice, reservation, payment_details)
    raise TypeError unless reservation.reservable.class == Event

    reservation.slots.each do |slot|
      description = "#{reservation.reservable.name}\n"
      description += if slot.start_at.to_date != slot.end_at.to_date
                       I18n.t('events.from_STARTDATE_to_ENDDATE',
                              STARTDATE: I18n.l(slot.start_at.to_date, format: :long),
                              ENDDATE: I18n.l(slot.end_at.to_date, format: :long)) + ' ' +
                         I18n.t('events.from_STARTTIME_to_ENDTIME',
                                STARTTIME: I18n.l(slot.start_at, format: :hour_minute),
                                ENDTIME: I18n.l(slot.end_at, format: :hour_minute))
                     else
                       "#{I18n.l slot.start_at.to_date, format: :long} #{I18n.l slot.start_at, format: :hour_minute}" \
                                        " - #{I18n.l slot.end_at, format: :hour_minute}"
                     end

      price_slot = payment_details[:elements][:slots].detect { |p_slot| p_slot[:start_at].to_time.in_time_zone == slot[:start_at] }
      invoice.invoice_items.push InvoiceItem.new(
        amount: price_slot[:price],
        description: description
      )
    end
  end

  ##
  # Generate an InvoiceItem for each slot in the given reservation and save them in invoice.invoice_items.
  # This method must be called if reservation.reservable is a Space, a Machine or a Training
  ##
  def self.generate_generic_item(invoice, reservation, payment_details)
    raise TypeError unless [Space, Machine, Training].include? reservation.reservable.class

    reservation.slots.each do |slot|
      description = reservation.reservable.name +
                    " #{I18n.l slot.start_at, format: :long} - #{I18n.l slot.end_at, format: :hour_minute}"

      price_slot = payment_details[:elements][:slots].detect { |p_slot| p_slot[:start_at].to_time.in_time_zone == slot[:start_at] }
      invoice.invoice_items.push InvoiceItem.new(
        amount: price_slot[:price],
        description: description
      )
    end
  end

  ##
  # Generate an InvoiceItem for the given subscription and save it in invoice.invoice_items.
  # This method must be called only with a valid subscription
  ##
  def self.generate_subscription_item(invoice, subscription, payment_details)
    raise TypeError unless subscription

    invoice.invoice_items.push InvoiceItem.new(
      amount: payment_details[:elements][:plan],
      description: subscription.plan.name,
      subscription_id: subscription.id
    )
  end


  ##
  # Set the total price to the reservation's invoice, summing its whole items.
  # Additionally a coupon may be applied to this invoice to make a discount on the total price
  # @param invoice {Invoice} the invoice to fill
  # @param user {User} the customer
  # @param [coupon] {Coupon} optional coupon to apply to the invoice
  ##
  def self.set_total_and_coupon(invoice, user, coupon = nil)
    return unless invoice

    total = invoice.invoice_items.map(&:amount).map(&:to_i).reduce(:+)

    unless coupon.nil?
      total = CouponService.new.apply(total, coupon, user.id)
      invoice.coupon_id = coupon.id
    end

    invoice.total = total
  end
end
