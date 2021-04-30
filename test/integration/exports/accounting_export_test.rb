# frozen_string_literal: true

require 'test_helper'
module Exports; end

class Exports::AccountingExportTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'export accounting period to ACD software' do
    # First, we create a new export
    post '/api/accounting/export',
         params: {
           query: {
             columns: %w[journal_code date account_code account_label piece line_label debit_origin credit_origin debit_euro credit_euro lettering],
             encoding: 'ISO-8859-1',
             date_format: '%d/%m/%Y',
             start_date: '2012-03-12T00:00:00.000Z',
             end_date: DateTime.current.utc.iso8601,
             label_max_length: 50,
             decimal_separator: ',',
             export_invoices_at_zero: false
           }.to_json.to_s,
           extension: 'csv',
           type: 'acd',
           key: ';'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Check the export was created correctly
    res = json_response(response.body)
    e = Export.where(id: res[:export_id]).first
    assert_not_nil e, 'Export was not created in database'

    # Run the worker
    worker = AccountingExportWorker.new
    worker.perform(e.id)

    # notification
    assert_not_empty Notification.where(attached_object: e)

    # resulting CSV file
    assert FileTest.exist?(e.file), 'CSV file was not generated'
    require 'csv'
    data = CSV.read(e.file, headers: true, col_sep: e.key)

    # test values
    # first line = client line
    journal_code = Setting.get('accounting_journal_code')
    assert_equal journal_code, data[0][I18n.t('accounting_export.journal_code')], 'Wrong journal code'

    first_invoice = Invoice.first
    entry_date = first_invoice.created_at.to_date
    assert_equal entry_date, DateTime.parse(data[0][I18n.t('accounting_export.date')]), 'Wrong date'

    if first_invoice.paid_by_card?
      card_client_code = Setting.get('accounting_card_client_code')
      assert_equal card_client_code, data[0][I18n.t('accounting_export.account_code')], 'Account code for card client is wrong'

      card_client_label = Setting.get('accounting_card_client_label')
      assert_equal card_client_label, data[0][I18n.t('accounting_export.account_label')], 'Account label for card client is wrong'
    else
      STDERR.puts "WARNING: unable to test accurately accounting export: invoice #{first_invoice.id} was not paid by card"
    end

    assert_equal first_invoice.reference, data[0][I18n.t('accounting_export.piece')], 'Piece (invoice reference) is wrong'

    if first_invoice.subscription_invoice?
      assert_match I18n.t('accounting_export.subscription'),
                   data[0][I18n.t('accounting_export.line_label')],
                   'Line label does not contains the reference to the invoiced item'
    else
      STDERR.puts "WARNING: unable to test accurately accounting export: invoice #{first_invoice.id} does not have a subscription"
    end

    if first_invoice.wallet_transaction_id.nil?
      assert_equal first_invoice.total / 100.00, data[0][I18n.t('accounting_export.debit_origin')].to_f, 'Origin debit amount does not match'
      assert_equal first_invoice.total / 100.00, data[0][I18n.t('accounting_export.debit_euro')].to_f, 'Euro debit amount does not match'
    else
      STDERR.puts "WARNING: unable to test accurately accounting export: invoice #{first_invoice.id} is using wallet"
    end

    assert_equal 0, data[0][I18n.t('accounting_export.credit_origin')].to_f, 'Credit origin amount does not match'
    assert_equal 0, data[0][I18n.t('accounting_export.credit_euro')].to_f, 'Credit euro amount does not match'

    # second line = sold item line
    assert_equal journal_code, data[1][I18n.t('accounting_export.journal_code')], 'Wrong journal code'
    assert_equal entry_date, DateTime.parse(data[1][I18n.t('accounting_export.date')]), 'Wrong date'

    if first_invoice.subscription_invoice?
      subscription_code = Setting.get('accounting_subscription_code')
      assert_equal subscription_code, data[1][I18n.t('accounting_export.account_code')], 'Account code for subscription is wrong'

      subscription_label = Setting.get('accounting_subscription_label')
      assert_equal subscription_label, data[1][I18n.t('accounting_export.account_label')], 'Account label for subscription is wrong'
    end

    assert_equal first_invoice.reference, data[1][I18n.t('accounting_export.piece')], 'Piece (invoice reference) is wrong'
    assert_match I18n.t('accounting_export.subscription'),
                 data[1][I18n.t('accounting_export.line_label')],
                 'Line label should be empty for non client lines'

    item = first_invoice.invoice_items.first
    assert_equal item.amount / 100.00, data[1][I18n.t('accounting_export.credit_origin')].to_f, 'Origin credit amount does not match'
    assert_equal item.amount / 100.00, data[1][I18n.t('accounting_export.credit_euro')].to_f, 'Euro credit amount does not match'

    assert_equal 0, data[1][I18n.t('accounting_export.debit_origin')].to_f, 'Debit origin amount does not match'
    assert_equal 0, data[1][I18n.t('accounting_export.debit_euro')].to_f, 'Debit euro amount does not match'

    # test with another invoice
    machine_invoice = Invoice.find(5)
    client_row = data[data.length - 4]
    item_row = data[data.length - 3]

    if machine_invoice.invoiced_type == 'Reservation' && machine_invoice.invoiced.reservable_type == 'Machine'
      assert_match I18n.t('accounting_export.Machine_reservation'),
                   client_row[I18n.t('accounting_export.line_label')],
                   'Line label does not contains the reference to the invoiced item'

      machine_code = Setting.get('accounting_Machine_code')
      assert_equal machine_code, item_row[I18n.t('accounting_export.account_code')], 'Account code for machine reservation is wrong'

      machine_label = Setting.get('accounting_Machine_label')
      assert_equal machine_label, item_row[I18n.t('accounting_export.account_label')], 'Account label for machine reservation is wrong'

    else
      STDERR.puts "WARNING: unable to test accurately accounting export: invoice #{machine_invoice.id} is not a Machine reservation"
    end

    # Clean CSV file
    require 'fileutils'
    FileUtils.rm(e.file)
  end
end
