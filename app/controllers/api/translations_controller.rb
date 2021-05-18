# frozen_string_literal: true

# API Controller for managing front-end translations
class API::TranslationsController < API::ApiController
  before_action :set_locale

  def show
    translations = I18n.t params[:state]
    if translations.class.name == String.name && translations.start_with?('translation missing')
      render json: { error: translations }, status: :unprocessable_entity
    else
      path = params[:state]
      res = path.split('.').reverse.reduce(translations) { |r, e| { e.to_sym => r } }
      render json: res, status: :ok
    end
  end

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

end
