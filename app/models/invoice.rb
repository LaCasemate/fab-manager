# frozen_string_literal: true

# Invoice correspond to a single purchase made by an user. This purchase may
# include reservation(s) and/or a subscription
class Invoice < PaymentDocument
  include NotifyWith::NotificationAttachedObject
  require 'fileutils'
  scope :only_invoice, -> { where(type: nil) }
  belongs_to :invoiced, polymorphic: true

  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items
  belongs_to :invoicing_profile
  belongs_to :statistic_profile
  belongs_to :wallet_transaction
  belongs_to :coupon

  belongs_to :subscription, foreign_type: 'Subscription', foreign_key: 'invoiced_id'
  belongs_to :reservation, foreign_type: 'Reservation', foreign_key: 'invoiced_id'
  belongs_to :offer_day, foreign_type: 'OfferDay', foreign_key: 'invoiced_id'

  has_one :avoir, class_name: 'Invoice', foreign_key: :invoice_id, dependent: :destroy
  has_one :payment_schedule_item
  has_one :payment_gateway_object, as: :item
  belongs_to :operator_profile, foreign_key: :operator_profile_id, class_name: 'InvoicingProfile'

  before_create :add_environment
  after_create :update_reference, :chain_record
  after_commit :generate_and_send_invoice, on: [:create], if: :persisted?
  after_update :log_changes

  validates_with ClosedPeriodValidator

  def file
    dir = "invoices/#{invoicing_profile.id}"

    # create directories if they doesn't exists (invoice & invoicing_profile_id)
    FileUtils.mkdir_p dir
    "#{dir}/#{filename}"
  end

  def filename
    prefix = Setting.find_by(name: 'invoice_prefix').value_at(created_at)
    prefix ||= if created_at < Setting.find_by(name: 'invoice_prefix').first_update
                 Setting.find_by(name: 'invoice_prefix').first_value
               else
                 Setting.get('invoice_prefix')
               end
    "#{prefix}-#{id}_#{created_at.strftime('%d%m%Y')}.pdf"
  end

  def user
    invoicing_profile.user
  end

  def order_number
    PaymentDocumentService.generate_order_number(self)
  end

  # for debug & used by rake task "fablab:maintenance:regenerate_invoices"
  def regenerate_invoice_pdf
    pdf = ::PDF::Invoice.new(self, subscription&.expiration_date).render
    File.binwrite(file, pdf)
  end

  def build_avoir(attrs = {})
    raise CannotRefundError if refunded? == true || prevent_refund?

    avoir = Avoir.new(dup.attributes)
    avoir.type = 'Avoir'
    avoir.attributes = attrs
    avoir.reference = nil
    avoir.invoice_id = id
    # override created_at to compute CA in stats
    avoir.created_at = avoir.avoir_date
    avoir.total = 0
    # refunds of invoices with cash coupons: we need to ventilate coupons on paid items
    paid_items = 0
    refund_items = 0
    invoice_items.each do |ii|
      paid_items += 1 unless ii.amount.zero?
      next unless attrs[:invoice_items_ids].include? ii.id # list of items to refund (partial refunds)
      raise Exception if ii.invoice_item # cannot refund an item that was already refunded

      refund_items += 1 unless ii.amount.zero?
      avoir_ii = avoir.invoice_items.build(ii.dup.attributes)
      avoir_ii.created_at = avoir.avoir_date
      avoir_ii.invoice_item_id = ii.id
      avoir.total += avoir_ii.amount
    end
    # handle coupon
    unless avoir.coupon_id.nil?
      discount = avoir.total
      if avoir.coupon.type == 'percent_off'
        discount = avoir.total * avoir.coupon.percent_off / 100.0
      elsif avoir.coupon.type == 'amount_off'
        discount = (avoir.coupon.amount_off / paid_items) * refund_items
      else
        raise InvalidCouponError
      end
      avoir.total -= discount
    end
    avoir
  end

  def subscription_invoice?
    invoice_items.each do |ii|
      return true if ii.subscription
    end
    false
  end

  ##
  # Test if the current invoice has been refund, totally or partially.
  # @return {Boolean|'partial'}, true means fully refund, false means not refunded
  ##
  def refunded?
    if avoir
      invoice_items.each do |item|
        return 'partial' unless item.invoice_item
      end
      true
    else
      false
    end
  end

  ##
  # Check if the current invoice is about a training that was previously validated for the concerned user.
  # In that case refunding the invoice shouldn't be allowed.
  # Moreover, an invoice cannot be refunded if the users' account was deleted
  # @return {Boolean}
  ##
  def prevent_refund?
    return true if user.nil?

    if invoiced_type == 'Reservation' && invoiced.reservable_type == 'Training'
      user.trainings.include?(invoiced.reservable_id)
    else
      false
    end
  end

  # get amount total paid
  def amount_paid
    total - (wallet_amount || 0)
  end

  # return a summary of the payment means used
  def payment_means
    res = []
    res.push(means: :wallet, amount: wallet_amount) if wallet_transaction && wallet_amount.positive?
    if paid_by_card?
      res.push(means: :card, amount: amount_paid)
    else
      res.push(means: :other, amount: amount_paid)
    end
    res
  end

  def footprint_children
    invoice_items
  end

  def paid_by_card?
    !payment_gateway_object.nil? && payment_method == 'card'
  end

  private

  def generate_and_send_invoice
    return unless Setting.get('invoicing_module')

    unless Rails.env.test?
      puts "Creating an InvoiceWorker job to generate the following invoice: id(#{id}), invoiced_id(#{invoiced_id}), " \
           "invoiced_type(#{invoiced_type}), user_id(#{invoicing_profile.user_id})"
    end
    InvoiceWorker.perform_async(id, user&.subscription&.expired_at)
  end

  def log_changes
    return if Rails.env.test?
    return unless changed?

    puts "WARNING: Invoice update triggered [ id: #{id}, reference: #{reference} ]"
    puts '----------   changes   ----------'
    puts changes
    puts '---------------------------------'
  end

end
