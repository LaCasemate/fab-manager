# frozen_string_literal: false

# Provides the routine to export the accounting data to an external accounting software
class AccountingExportService
  include ActionView::Helpers::NumberHelper

  attr_reader :encoding, :format, :separator, :journal_code, :date_format, :columns, :decimal_separator, :label_max_length,
              :export_zeros

  def initialize(columns, encoding: 'UTF-8', format: 'CSV', separator: ';')
    @encoding = encoding
    @format = format
    @separator = separator
    @decimal_separator = ','
    @date_format = '%d/%m/%Y'
    @label_max_length = 50
    @export_zeros = false
    @journal_code = Setting.get('accounting_journal_code') || ''
    @date_format = date_format
    @columns = columns
  end

  def set_options(decimal_separator: ',', date_format: '%d/%m/%Y', label_max_length: 50, export_zeros: false)
    @decimal_separator = decimal_separator
    @date_format = date_format
    @label_max_length = label_max_length
    @export_zeros = export_zeros
  end

  def export(start_date, end_date, file)
    # build CSV content
    content = header_row
    invoices = Invoice.where('created_at >= ? AND created_at <= ?', start_date, end_date).order('created_at ASC')
    invoices = invoices.where('total > 0') unless export_zeros
    invoices.each do |i|
      puts "processing invoice #{i.id}..." unless Rails.env.test?
      content << generate_rows(i)
    end

    # write content to file
    File.open(file, "w:#{encoding}") { |f| f.puts content.encode(encoding, invalid: :replace, undef: :replace) }
  end

  private

  def header_row
    row = ''
    columns.each do |column|
      row << I18n.t("accounting_export.#{column}") << separator
    end
    "#{row}\n"
  end

  def generate_rows(invoice)
    rows = client_rows(invoice) + items_rows(invoice)

    vat = vat_row(invoice)
    rows += "#{vat}\n" unless vat.nil?

    rows
  end

  # Generate the "subscription" and "reservation" rows associated with the provided invoice
  def items_rows(invoice)
    rows = invoice.subscription_invoice? ? "#{subscription_row(invoice)}\n" : ''
    if invoice.invoiced_type == 'Reservation'
      items = invoice.invoice_items.select { |ii| ii.subscription.nil? }
      items.each do |item|
        rows << "#{reservation_row(invoice, item)}\n"
      end
    elsif invoice.invoiced_type == 'WalletTransaction'
      rows << "#{wallet_row(invoice)}\n"
    elsif invoice.invoiced_type == 'Error'
      items = invoice.invoice_items.select { |ii| ii.subscription.nil? }
      items.each do |item|
        rows << "#{error_row(invoice, item)}\n"
      end
    end
    rows
  end

  # Generate the "client" rows, which contains the debit to the client account, all taxes included
  def client_rows(invoice)
    rows = ''
    invoice.payment_means.each do |details|
      rows << row(
        invoice,
        account(invoice, :projets, means: details[:means]),
        account(invoice, :projets, means: details[:means], type: :label),
        details[:amount] / 100.00,
        line_label: label(invoice),
        debit_method: :debit_client,
        credit_method: :credit_client
      )
      rows << "\n"
    end
    rows
  end

  # Generate the "reservation" row, which contains the credit to the reservation account, all taxes excluded
  def reservation_row(invoice, item)
    row(
      invoice,
      account(invoice, :reservation),
      account(invoice, :reservation, type: :label),
      item.net_amount / 100.00,
      line_label: label(invoice)
    )
  end

  # Generate the "subscription" row, which contains the credit to the subscription account, all taxes excluded
  def subscription_row(invoice)
    subscription_item = invoice.invoice_items.select(&:subscription).first
    row(
      invoice,
      account(invoice, :subscription),
      account(invoice, :subscription, type: :label),
      subscription_item.net_amount / 100.00,
      line_label: label(invoice)
    )
  end

  # Generate the "wallet" row, which contains the credit to the wallet account, all taxes excluded
  # This applies to wallet crediting, when an Avoir is generated at this time
  def wallet_row(invoice)
    row(
      invoice,
      account(invoice, :wallet),
      account(invoice, :wallet, type: :label),
      invoice.invoice_items.first.net_amount / 100.00,
      line_label: label(invoice)
    )
  end

  # Generate the "VAT" row, which contains the credit to the VAT account, with VAT amount only
  def vat_row(invoice)
    rate = VatHistoryService.new.invoice_vat(invoice)
    # we do not render the VAT row if it was disabled for this invoice
    return nil if rate.zero?

    row(
      invoice,
      account(invoice, :vat),
      account(invoice, :vat, type: :label),
      invoice.invoice_items.map(&:vat).map(&:to_i).reduce(:+) / 100.00,
      line_label: label(invoice)
    )
  end

  def error_row(invoice, item)
    row(
      invoice,
      account(invoice, :error),
      account(invoice, :error, type: :label),
      item.net_amount / 100.00,
      line_label: label(invoice)
    )
  end

  # Generate a row of the export, filling the configured columns with the provided values
  def row(invoice, account_code, account_label, amount, line_label: '', debit_method: :debit, credit_method: :credit)
    row = ''
    columns.each do |column|
      case column
      when 'journal_code'
        row << journal_code
      when 'date'
        row << invoice.created_at&.strftime(date_format)
      when 'account_code'
        row << account_code
      when 'account_label'
        row << account_label
      when 'piece'
        row << invoice.reference
      when 'line_label'
        row << line_label
      when 'debit_origin'
        row << method(debit_method).call(invoice, amount)
      when 'credit_origin'
        row << method(credit_method).call(invoice, amount)
      when 'debit_euro'
        row << method(debit_method).call(invoice, amount)
      when 'credit_euro'
        row << method(credit_method).call(invoice, amount)
      when 'lettering'
        row << ''
      else
        puts "Unsupported column: #{column}"
      end
      row << separator
    end
    row
  end

  # Get the account code (or label) for the given invoice and the specified line type (client, vat, subscription or reservation)
  def account(invoice, account, type: :code, means: :other)
    case account
    when :projets
      Setting.find_by(name: "accounting_#{means}_client_#{type}")&.value
    when :vat
      Setting.find_by(name: "accounting_VAT_#{type}")&.value
    when :subscription
      if invoice.subscription_invoice?
        Setting.find_by(name: "accounting_subscription_#{type}")&.value
      else
        puts "WARN: Invoice #{invoice.id} has no subscription"
      end
    when :reservation
      if invoice.invoiced_type == 'Reservation'
        Setting.find_by(name: "accounting_#{invoice.invoiced.reservable_type}_#{type}")&.value
      else
        puts "WARN: Invoice #{invoice.id} has no reservation"
      end
    when :wallet
      if invoice.invoiced_type == 'WalletTransaction'
        Setting.find_by(name: "accounting_wallet_#{type}")&.value
      else
        puts "WARN: Invoice #{invoice.id} is not a wallet credit"
      end
    when :error
      Setting.find_by(name: "accounting_Error_#{type}")&.value
    else
      puts "Unsupported account #{account}"
    end || ''
  end

  # Fill the value of the "debit" column: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def debit(invoice, amount)
    avoir = invoice.is_a? Avoir
    avoir ? format_number(amount) : '0'
  end

  # Fill the value of the "credit" column: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def credit(invoice, amount)
    avoir = invoice.is_a? Avoir
    avoir ? '0' : format_number(amount)
  end

  # Fill the value of the "debit" column for the client row: if the invoice is a refund, returns 0, otherwise, returns the given amount
  def debit_client(invoice, amount)
    credit(invoice, amount)
  end

  # Fill the value of the "credit" column, for the client row: if the invoice is a refund, returns the given amount, returns 0 otherwise
  def credit_client(invoice, amount)
    debit(invoice, amount)
  end

  # Format the given number as a string, using the configured separator
  def format_number(num)
    number_to_currency(num, unit: '', separator: decimal_separator, delimiter: '', precision: 2)
  end

  # Create a text from the given invoice, matching the accounting software rules for the labels
  def label(invoice)
    name = "#{invoice.invoicing_profile.last_name} #{invoice.invoicing_profile.first_name}".tr separator, ''
    reference = invoice.reference

    items = invoice.subscription_invoice? ? [I18n.t('accounting_export.subscription')] : []
    items.push I18n.t("accounting_export.#{invoice.reservation.reservable_type}_reservation") if invoice.invoiced_type == 'Reservation'
    items.push I18n.t('accounting_export.wallet') if invoice.invoiced_type == 'WalletTransaction'

    summary = items.join(' + ')
    res = "#{reference}, #{summary}"
    "#{name.truncate(label_max_length - res.length)}, #{res}"
  end
end
