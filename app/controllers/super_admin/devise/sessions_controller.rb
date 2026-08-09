# frozen_string_literal: true

class SuperAdmin::Devise::SessionsController < Devise::SessionsController
  include SuperAdmin::LocaleSwitchable

  def new
    self.resource = resource_class.new(sign_in_params)
  end

  def create
    redirect_to(super_admin_session_path, flash: { error: @error_message }) && return unless valid_credentials?

    sign_in(:super_admin, @super_admin)
    persist_super_admin_locale!(session[:super_admin_locale]) if session[:super_admin_locale].present?
    flash.discard
    redirect_to super_admin_users_path
  end

  def destroy
    sign_out
    flash.discard
    redirect_to '/'
  end

  private

  def valid_credentials?
    @super_admin = SuperAdmin.find_by!(email: params[:super_admin][:email])
    raise StandardError, 'Invalid Password' unless @super_admin.valid_password?(params[:super_admin][:password])

    true
  rescue StandardError => e
    Rails.logger.error e.message
    @error_message = I18n.t('super_admin.sessions.invalid_credentials')
    false
  end
end
