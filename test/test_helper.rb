# frozen_string_literal: true

require 'coveralls'
Coveralls.wear!('rails')

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'action_dispatch'
require 'rails/test_help'
require 'vcr'
require 'sidekiq/testing'
require 'minitest/reporters'

include ActionDispatch::TestProcess

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
end

Sidekiq::Testing.fake!
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true)]

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
  ActiveRecord::Migration.check_pending!
  fixtures :all

  def json_response(body)
    JSON.parse(body, symbolize_names: true)
  end

  def default_headers
    { 'Accept' => Mime[:json], 'Content-Type' => Mime[:json].to_s }
  end

  def stripe_payment_method(error: nil)
    number = '4242424242424242'
    exp_month = 4
    exp_year = DateTime.current.next_year.year
    cvc = '314'

    case error
    when /card_declined/
      number = '4000000000000002'
    when /incorrect_number/
      number = '4242424242424241'
    when /invalid_expiry_month/
      exp_month = 15
    when /invalid_expiry_year/
      exp_year = 1964
    when /invalid_cvc/
      cvc = '99'
    end

    Stripe::PaymentMethod.create(
      {
        type: 'card',
        card: {
          number: number,
          exp_month: exp_month,
          exp_year: exp_year,
          cvc: cvc
        }
      },
      { api_key: Setting.get('stripe_secret_key') }
    ).id
  end

  # Force the invoice generation worker to run NOW and check the resulting file generated.
  # Delete the file afterwards.
  # @param invoice {Invoice}
  def assert_invoice_pdf(invoice)
    assert_not_nil invoice, 'Invoice was not created'

    invoice_worker = InvoiceWorker.new
    invoice_worker.perform(invoice.id, invoice&.user&.subscription&.expired_at)

    assert File.exist?(invoice.file), 'Invoice PDF was not generated'

    # now we check the file content
    reader = PDF::Reader.new(invoice.file)
    assert_equal 1, reader.page_count # single page invoice

    ht_amount = invoice.total
    page = reader.pages.first
    lines = page.text.scan(/^.+/)
    lines.each do |line|
      # check that the numbers printed into the PDF file match the total stored in DB
      if line.include? I18n.t('invoices.total_amount')
        assert_equal invoice.total / 100.0, parse_amount_from_invoice_line(line), 'Invoice total rendered in the PDF file does not match'
      end

      # check that the VAT was correctly applied if it was configured
      ht_amount = parse_amount_from_invoice_line(line) if line.include? I18n.t('invoices.including_total_excluding_taxes')
    end

    vat_service = VatHistoryService.new
    vat_rate = vat_service.invoice_vat(invoice)
    if vat_rate.positive?
      computed_ht = sprintf('%.2f', (invoice.total / (vat_rate / 100.00 + 1)) / 100.00).to_f

      assert_equal computed_ht, ht_amount, 'Total excluding taxes rendered in the PDF file is not computed correctly'
    else
      assert_equal invoice.total, ht_amount, 'VAT information was rendered in the PDF file despite that VAT was disabled'
    end

    # check the recipient & the address
    if invoice.invoicing_profile.organization
      assert lines.first.include?(invoice.invoicing_profile.organization.name), 'On the PDF invoice, organization name is invalid'
      assert invoice.invoicing_profile.organization.address.address.include?(lines[2].split('             ').last.strip), 'On the PDF invoice, organization address is invalid'
    else
      assert lines.first.include?(invoice.invoicing_profile.full_name), 'On the PDF invoice, customer name is invalid'
      assert invoice.invoicing_profile.address.address.include?(lines[2].split('             ').last.strip), 'On the PDF invoice, customer address is invalid'
    end
    # check the email
    assert lines[1].include?(invoice.invoicing_profile.email), 'On the PDF invoice, email is invalid'

    File.delete(invoice.file)
  end

  # Force the statistics export generation worker to run NOW and check the resulting file generated.
  # Delete the file afterwards.
  # @param export {Export}
  def assert_export_xlsx(export)
    assert_not_nil export, 'Export was not created'

    if export.category == 'statistics'
      export_worker = StatisticsExportWorker.new
      export_worker.perform(export.id)

      assert File.exist?(export.file), 'Export XLSX was not generated'

      File.delete(export.file)
    else
      skip('Unable to test export which is not of the category "statistics"')
    end
  end

  def assert_archive(accounting_period)
    assert_not_nil accounting_period, 'AccountingPeriod was not created'

    archive_worker = ArchiveWorker.new
    archive_worker.perform(accounting_period.id)

    assert FileTest.exist?(accounting_period.archive_file), 'ZIP archive was not generated'

    # Extract archive
    require 'tmpdir'
    require 'fileutils'
    dest = "#{Dir.tmpdir}/accounting/#{accounting_period.id}"
    FileUtils.mkdir_p "#{dest}/accounting"
    Zip::File.open(accounting_period.archive_file) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to file/directory/symlink
        entry.extract("#{dest}/#{entry.name}")
      end
    end

    # Check archive matches
    require 'integrity/checksum'
    sumfile = File.read("#{dest}/checksum.sha256").split("\t")
    assert_equal sumfile[0], Integrity::Checksum.file("#{dest}/#{sumfile[1]}"), 'archive checksum does not match'

    archive = File.read("#{dest}/#{sumfile[1]}")
    archive_json = JSON.parse(archive)
    invoices = Invoice.where(
      'created_at >= :start_date AND created_at <= :end_date',
      start_date: accounting_period.start_at.to_datetime, end_date: accounting_period.end_at.to_datetime
    )

    assert_equal invoices.count, archive_json['invoices'].count
    assert_equal accounting_period.footprint, archive_json['period_footprint']

    require 'version'
    assert_equal Version.current, archive_json['software']['version']

    # we clean up the files before quitting
    FileUtils.rm_rf(dest)
    FileUtils.rm_rf(accounting_period.archive_folder)
  end

  def assert_dates_equal(expected, actual, msg = nil)
    assert_not_nil actual, msg
    assert_equal expected.to_date, actual.to_date, msg
  end

  private

  # Parse a line of text read from a PDF file and return the price included inside
  # Line of text should be of form 'Label              $10.00'
  # @returns {float}
  def parse_amount_from_invoice_line(line)
    line[line.rindex(' ') + 1..-1].tr(I18n.t('number.currency.format.unit'), '').to_f
  end
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
end
