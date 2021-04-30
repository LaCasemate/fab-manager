# frozen_string_literal: true

require 'integrity/checksum'
require 'version'
require 'zip'

# AccountingPeriod is a period of N days (N > 0) which as been closed by an admin
# to prevent writing new accounting lines (invoices & refunds) during this period of time.
class AccountingPeriod < ApplicationRecord
  before_destroy { false }
  before_update { false }
  before_create :compute_totals
  after_commit :archive_closed_data, on: [:create]

  validates :start_at, :end_at, :closed_at, :closed_by, presence: true
  validates_with DateRangeValidator
  validates_with DurationValidator
  validates_with PastPeriodValidator
  validates_with PeriodOverlapValidator
  validates_with PeriodIntegrityValidator

  def delete
    false
  end

  def invoices
    Invoice.where('created_at >= :start_date AND CAST(created_at AS DATE) <= :end_date', start_date: start_at, end_date: end_at)
  end

  def invoices_with_vat(invoices)
    vat_service = VatHistoryService.new
    invoices.map do |i|
      { invoice: i, vat_rate: vat_service.invoice_vat(i) / 100.0 }
    end
  end

  def archive_folder
    dir = "accounting/#{id}"
    dir = "test/fixtures/files/accounting/#{id}" if Rails.env.test?

    # create directory if it doesn't exists (accounting)
    FileUtils.mkdir_p dir
    dir
  end

  def archive_file
    "#{archive_folder}/#{start_at.iso8601}_#{end_at.iso8601}.zip"
  end

  def archive_json_file
    "#{start_at.iso8601}_#{end_at.iso8601}.json"
  end

  def check_footprint
    footprint == compute_footprint
  end

  def previous_period
    AccountingPeriod.where('closed_at < ?', closed_at).order(closed_at: :desc).limit(1).last
  end

  private

  def archive_closed_data
    ArchiveWorker.perform_async(id)
  end

  def price_without_taxe(invoice)
    invoice[:invoice].total - (invoice[:invoice].total * invoice[:vat_rate])
  end

  def compute_totals
    period_invoices = invoices_with_vat(invoices.where(type: nil))
    period_avoirs = invoices_with_vat(invoices.where(type: 'Avoir'))
    self.period_total = (period_invoices.map(&method(:price_without_taxe)).reduce(:+) || 0) -
                        (period_avoirs.map(&method(:price_without_taxe)).reduce(:+) || 0)

    all_invoices = invoices_with_vat(Invoice.where('CAST(created_at AS DATE) <= :end_date AND type IS NULL', end_date: end_at))
    all_avoirs = invoices_with_vat(Invoice.where("CAST(created_at AS DATE) <= :end_date AND type = 'Avoir'", end_date: end_at))
    self.perpetual_total = (all_invoices.map(&method(:price_without_taxe)).reduce(:+) || 0) -
                           (all_avoirs.map(&method(:price_without_taxe)).reduce(:+) || 0)
    self.footprint = compute_footprint
  end

  def compute_footprint
    columns = AccountingPeriod.columns.map(&:name)
                              .delete_if { |c| %w[id footprint created_at updated_at].include? c }

    Integrity::Checksum.text("#{columns.map { |c| self[c] }.join}#{previous_period ? previous_period.footprint : ''}")
  end
end
