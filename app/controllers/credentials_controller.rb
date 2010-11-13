class CredentialsController < InheritedResources::Base
  before_filter :authenticate_user!
  before_filter :check_if_admin

  def check_if_admin
    unless current_user.admin?
      flash[:alert] = "Access denied. You must be an administrator."  
      redirect_to root_url
    end
  end

end