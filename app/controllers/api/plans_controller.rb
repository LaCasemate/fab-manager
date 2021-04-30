# frozen_string_literal: true

# API Controller for resources of type Plan and PartnerPlan.
# Plan are used to define subscription's characteristics.
# PartnerPlan is a special kind of plan which send notifications to an external user
class API::PlansController < API::ApiController
  before_action :authenticate_user!, except: [:index]

  def index
    @plans = Plan.includes(:plan_file)
    @plans = @plans.where(group_id: params[:group_id]) if params[:group_id]
    render :index
  end

  def show
    @plan = Plan.find(params[:id])
  end

  def create
    authorize Plan

    unless %w[PartnerPlan Plan].include? plan_params[:type]
      render json: { error: 'unhandled plan type' }, status: :unprocessable_entity and return
    end

    type = plan_params[:type]
    partner = params[:plan][:partner_id].empty? ? nil : User.find(params[:plan][:partner_id])

    res = PlansService.create(type, partner, plan_params)
    if res.errors
      render json: res.errors, status: :unprocessable_entity
    else
      render json: res, status: :created
    end
  end

  def update
    @plan = Plan.find(params[:id])
    authorize @plan
    if @plan.update(plan_params)
      render :show, status: :ok
    else
      render json: @plan.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @plan = Plan.find(params[:id])
    authorize @plan
    @plan.destroy
    head :no_content
  end

  private

  def plan_params
    # parameters caching for performance
    if @parameters
      @parameters
    else
      @parameters = params
      @parameters[:plan][:amount] = @parameters[:plan][:amount].to_f * 100.0 if @parameters[:plan][:amount]
      if @parameters[:plan][:prices_attributes]
        @parameters[:plan][:prices_attributes] = @parameters[:plan][:prices_attributes].map do |price|
          { amount: price[:amount].to_f * 100.0, id: price[:id] }
        end
      end

      @parameters = @parameters.require(:plan)
                               .permit(:base_name, :type, :group_id, :amount, :interval, :interval_count, :is_rolling,
                                       :training_credit_nb, :ui_weight, :disabled, :monthly_payment, :description,
                                       plan_file_attributes: %i[id attachment _destroy],
                                       prices_attributes: %i[id amount])
    end
  end
end
