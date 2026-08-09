class SuperAdmin::LocalesController < SuperAdmin::ApplicationController
  skip_before_action :authenticate_super_admin!

  def update
    persist_super_admin_locale!(params[:locale])
    redirect_back(fallback_location: fallback_path)
  end

  private

  def fallback_path
    super_admin_signed_in? ? super_admin_root_path : new_super_admin_session_path
  end
end
