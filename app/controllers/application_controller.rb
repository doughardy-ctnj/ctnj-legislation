class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :store_current_location, :unless => :devise_controller?

  private

  def user_not_authorized
    flash[:alert] = "You must login to continue."
    redirect_to(user_facebook_omniauth_authorize_path)
  end

  def store_current_location
    store_location_for(:user, request.url)
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || request.referer || root_path
  end
end
