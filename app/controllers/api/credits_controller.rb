# frozen_string_literal: true

# API Controller for resources of type Credit
# Credits are used to give free reservations to users
class API::CreditsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_credit, only: %i[show update destroy]

  def index
    authorize Credit
    @credits = if params
                 Credit.includes(:creditable).where(params.permit(:creditable_type))
               else
                 Credit.includes(:creditable).all
               end
  end

  def create
    authorize Credit
    @credit = Credit.new(credit_params)
    if @credit.save
      render :show, status: :created, location: @credit
    else
      render json: @credit.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Credit
    if @credit.update(credit_params)
      render :show, status: :ok, location: @credit
    else
      render json: @credit.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Credit
    @credit.destroy
    head :no_content
  end

  private

  def set_credit
    @credit = Credit.find(params[:id])
  end

  def credit_params
    params.require(:credit).permit(:creditable_id, :creditable_type, :plan_id, :hours)
  end
end
