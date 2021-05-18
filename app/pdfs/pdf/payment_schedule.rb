# frozen_string_literal: true

# Generate a downloadable PDF file for the recorded payment schedule
class PDF::PaymentSchedule < Prawn::Document
  require 'stringio'
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  ##
  # @param payment_schedule {PaymentSchedule}
  ##
  def initialize(payment_schedule)
    super(margin: 70)

    # fonts
    opensans = Rails.root.join('vendor/assets/fonts/OpenSans-Regular.ttf').to_s
    opensans_bold = Rails.root.join('vendor/assets/fonts/OpenSans-Bold.ttf').to_s
    opensans_bolditalic = Rails.root.join('vendor/assets/fonts/OpenSans-BoldItalic.ttf').to_s
    opensans_italic = Rails.root.join('vendor/assets/fonts/OpenSans-Italic.ttf').to_s

    font_families.update(
      'Open-Sans' => {
        normal: { file: opensans, font: 'Open-Sans' },
        bold: { file: opensans_bold, font: 'Open-Sans-Bold' },
        italic: { file: opensans_italic, font: 'Open-Sans-Oblique' },
        bold_italic: { file: opensans_bolditalic, font: 'Open-Sans-BoldOblique' }
      }
    )

    # logo
    img_b64 = Setting.find_by(name: 'invoice_logo')
    begin
      image StringIO.new(Base64.decode64(img_b64.value)), fit: [415, 40]
    rescue StandardError => e
      puts "Unable to decode invoice logo from base64: #{e}"
    end
    move_down 20
    font('Open-Sans', size: 10) do
      # general information
      text I18n.t('payment_schedules.schedule_reference', REF: payment_schedule.reference), leading: 3
      text I18n.t('payment_schedules.schedule_issued_on_DATE', DATE: I18n.l(payment_schedule.created_at.to_date))

      # user/organization's information
      if payment_schedule.invoicing_profile&.organization
        name = payment_schedule.invoicing_profile.organization.name
        full_name = "#{name} (#{payment_schedule.invoicing_profile.full_name})"
      else
        name = payment_schedule.invoicing_profile.full_name
        full_name = name
      end

      address = if payment_schedule.invoicing_profile&.organization&.address
                  payment_schedule.invoicing_profile.organization.address.address
                elsif payment_schedule.invoicing_profile&.address
                  payment_schedule.invoicing_profile.address.address
                else
                  ''
                end

      text_box "<b>#{name}</b>\n#{payment_schedule.invoicing_profile.email}\n#{address}",
               at: [bounds.width - 130, bounds.top - 49],
               width: 130,
               align: :right,
               inline_format: true
      name = full_name
      subscription = Subscription.find(payment_schedule.payment_schedule_items.first.details['subscription_id'])

      # object
      move_down 25
      text I18n.t('payment_schedules.object', ITEM: subscription_verbose(subscription, name))

      # details table of the deadlines
      move_down 20
      text I18n.t('payment_schedules.deadlines'), leading: 4
      move_down 2
      data = [[I18n.t('payment_schedules.deadline_date'), I18n.t('payment_schedules.deadline_amount')]]

      # going through the payment_schedule_items
      payment_schedule.payment_schedule_items.each do |item|

        price = item.amount.to_i / 100.00
        date = I18n.l(item.due_date.to_date)

        data += [[date, number_to_currency(price)]]
      end
      data += [[I18n.t('payment_schedules.total_amount'), number_to_currency(payment_schedule.total / 100.0)]]

      # display table
      font_size(8) do
        table(data, header: true, column_widths: [400, 72], cell_style: { inline_format: true }) do
          row(0).font_style = :bold
          column(1).style align: :right
          row(-1).style align: :right
          row(-1).background_color = 'E4E4E4'
          row(-1).font_style = :bold
        end
      end

      # payment method
      move_down 20
      payment_verbose = _t('payment_schedules.settlement_by_METHOD', METHOD: payment_schedule.payment_method)
      if payment_schedule.wallet_amount
        payment_verbose += I18n.t('payment_schedules.settlement_by_wallet',
                                  AMOUNT: number_to_currency(payment_schedule.wallet_amount / 100.00))
      end
      text payment_verbose

      # important information
      move_down 40
      txt = parse_html(Setting.get('invoice_text'))
      txt.each_line do |line|
        text line, style: :bold, inline_format: true
      end


      # address and legals information
      move_down 40
      txt = parse_html(Setting.get('invoice_legals'))
      txt.each_line do |line|
        text line, align: :right, leading: 4, inline_format: true
      end
    end

    # factice watermark
    return unless %w[staging test development].include?(payment_schedule.environment)

    transparent(0.1) do
      rotate(45, origin: [0, 0]) do
        image "#{Rails.root}/app/pdfs/data/watermark-#{I18n.default_locale}.png", at: [90, 150]
      end
    end
  end

  private

  def subscription_verbose(subscription, username)
    subscription_start_at = subscription.expired_at - subscription.plan.duration
    duration_verbose = I18n.t("duration.#{subscription.plan.interval}", count: subscription.plan.interval_count)
    I18n.t('payment_schedules.subscription_of_NAME_for_DURATION_starting_from_DATE',
           NAME: username,
           DURATION: duration_verbose,
           DATE: I18n.l(subscription_start_at.to_date))
  end

  ##
  # Remove every unsupported html tag from the given html text (like <p>, <span>, ...).
  # The supported tags are <b>, <u>, <i> and <br>.
  # @param html [String] single line html text
  # @return [String] multi line simplified html text
  ##
  def parse_html(html)
    ActionController::Base.helpers.sanitize(html, tags: %w[b u i br])
  end
end
