class ApplicationController < ActionController::Base
	 before_action :configure_permitted_parameters, if: :devise_controller?
	 protect_from_forgery prepend: true
	 require 'roo'
	 require 'rqrcode'

	def check2_bill(mmb)
    mmb = PtnsMmb.find(mmb)
    mmb.payments.where(paid: false).each do |pmt|
      url_bill = "#{ENV['BILLPLZ_API']}bills/#{pmt.bill_id}"
      data_billplz = HTTParty.get(url_bill.to_str,
              :body  => { }.to_json, 
                          #:callback_url=>  "YOUR RETURN URL"}.to_json,
              :basic_auth => { :username => "#{ENV['BILLPLZ_APIKEY']}" },
              :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
      #render json: data_billplz and return
      data = JSON.parse(data_billplz.to_s)
      if data["id"].present?
        if data["paid"] == true
        	pmt.paid = true
        	pmt.pdt = data["paid_at"]
        	pmt.save
        	mmb.stat = "Aktif"
        	mmb.save
        	return true 
        else
          pmt.destroy
        end
      end

    end #end loop
  end #end function

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
