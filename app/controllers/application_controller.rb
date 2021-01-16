class ApplicationController < ActionController::Base
	 before_action :configure_permitted_parameters, if: :devise_controller?
	 protect_from_forgery prepend: true
	 require 'roo'
	 require 'rqrcode'

	 #def current_taska
	 	#return unless session[:Taska_id]
	 	#@current_taska ||= Taska.find(session[:Taska_id])
	 #end

	 

	 

  protected

  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
