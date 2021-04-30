# frozen_string_literal: true

# API Controller for resources of PaymentSchedule
class API::PaymentSchedulesController < API::ApiController
  before_action :authenticate_user!
  before_action :set_payment_schedule, only: %i[download cancel]
  before_action :set_payment_schedule_item, only: %i[cash_check refresh_item pay_item]

  def index
    @payment_schedules = PaymentSchedule.where('invoicing_profile_id = ?', current_user.invoicing_profile.id)
                                        .includes(:invoicing_profile, :payment_schedule_items, :subscription)
                                        .joins(:invoicing_profile)
                                        .order('payment_schedules.created_at DESC')
                                        .page(params[:page])
                                        .per(params[:size])
  end

  def list
    authorize PaymentSchedule

    p = params.require(:query).permit(:reference, :customer, :date, :page, :size)

    render json: { error: 'page must be an integer' }, status: :unprocessable_entity and return unless p[:page].is_a? Integer
    render json: { error: 'size must be an integer' }, status: :unprocessable_entity and return unless p[:size].is_a? Integer

    @payment_schedules = PaymentScheduleService.list(
      p[:page],
      p[:size],
      reference: p[:reference], customer: p[:customer], date: p[:date]
    )
  end

  def download
    authorize @payment_schedule
    send_file File.join(Rails.root, @payment_schedule.file), type: 'application/pdf', disposition: 'attachment'
  end

  def cash_check
    authorize @payment_schedule_item.payment_schedule
    PaymentScheduleService.new.generate_invoice(@payment_schedule_item, payment_method: 'check')
    attrs = { state: 'paid', payment_method: 'check' }
    @payment_schedule_item.update_attributes(attrs)

    render json: attrs, status: :ok
  end

  def refresh_item
    authorize @payment_schedule_item.payment_schedule
    PaymentScheduleItemWorker.new.perform(@payment_schedule_item.id)

    render json: { state: 'refreshed' }, status: :ok
  end

  def pay_item
    authorize @payment_schedule_item.payment_schedule
    # FIXME
    stripe_key = Setting.get('stripe_secret_key')
    stp_invoice = Stripe::Invoice.pay(@payment_schedule_item.payment_gateway_object.gateway_object_id, {}, { api_key: stripe_key })
    PaymentScheduleItemWorker.new.perform(@payment_schedule_item.id)

    render json: { status: stp_invoice.status }, status: :ok
  rescue Stripe::StripeError => e
    stripe_key = Setting.get('stripe_secret_key')
    stp_invoice = Stripe::Invoice.retrieve(@payment_schedule_item.payment_gateway_object.gateway_object_id, api_key: stripe_key)
    PaymentScheduleItemWorker.new.perform(@payment_schedule_item.id)

    render json: { status: stp_invoice.status, error: e }, status: :unprocessable_entity
  end

  def cancel
    authorize @payment_schedule

    canceled_at = PaymentScheduleService.cancel(@payment_schedule)
    render json: { canceled_at: canceled_at }, status: :ok
  end

  private

  def set_payment_schedule
    @payment_schedule = PaymentSchedule.find(params[:id])
  end

  def set_payment_schedule_item
    @payment_schedule_item = PaymentScheduleItem.find(params[:id])
  end
end
