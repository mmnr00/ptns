class TaskasController < ApplicationController
  
  require 'json'
  before_action :set_taska, only: [:show,:children_index, :taskateachers, :taskateachers_classroom,:classrooms_index, :edit, :update, :destroy]
  before_action :set_all
  before_action :check_admin, only: [:show]
  before_action :authenticate_admin!, only: [:new]

  # GET /taskas
  # GET /taskas.json
  def index
    @taskas = Taska.all
  end

  def index_parent
    @parent = current_parent
    @taskas = Taska.all.where.not(name: "Taska admin master").where.not(name: "TASKA Wma").where.not(name: "taska mirror tsp")
  end

  def taska_pricing
  end

  def taska_page
    @taska = Taska.find(params[:id])
    @fotos = @taska.fotos
  end

  def unreg_kids
    @taska = Taska.find(params[:id])
    @kid = Kid.new
    @unregistered_kids = @taska.kids.where(classroom_id: nil).order('name ASC')
    @taska_classrooms = @taska.classrooms
    render action: "unreg_kids", layout: "dsb-admin-overview"
  end

  def childlist_xls
    @taska = Taska.find(params[:id])
    @taska_kids = @taska.kids.order('name ASC')
    respond_to do |format|
      #format.html
      format.xlsx{
                  response.headers['Content-Disposition'] = 'attachment; filename="Children List.xlsx"'
      }
    end
  end

  def add_subdomain
    @taska = Taska.find(params[:id])
    subdomain = params[:taska][:subdomain]
    exist = Taska.where(subdomain: subdomain)
    if exist.present?
      flash[:danger] = "Website name not available. Please choose another name"
    else
      @taska.subdomain = subdomain
      @taska.save
      flash[:success] = "Website name successfully added"
    end
    redirect_to taska_path(@taska)
  end

  def find_child
    #@classroom = Classroom.find(params[:id])
    @taska = Taska.find(params[:id])
    @kid = Kid.find(params[:child])
    if params[:name].blank? 
      flash.now[:danger] = "You have entered an empty request"
    else
      @kid_search = @taska.kids.where("name like?", "%#{params[:name].upcase}%" ).where.not(classroom_id: nil)
      flash.now[:danger] = "Cannot find child" unless @kid_search.present?
    end
    respond_to do |format|
      format.js { render partial: 'taskas/result' } 
    end
  end

  def taska_receipts
    @taska = Taska.find(params[:id])
    @taska_receipts = @taska.payments.where(name: "TASKA PLAN").where(paid: true)
    render action: "taska_receipts", layout: "dsb-admin-overview" 
  end

  def all_bills
    @taska = Taska.find(params[:id])
    @kid = Kid.find(params[:kid_id])
    @kid_bills = @kid.payments.order("paid ASC").order("updated_at ASC")
    render action: "all_bills", layout: "dsb-admin-classroom"
  end

  def remove_taska
    @kid = Kid.find(params[:kid])
    @taska = @kid.taska
    if (bill =@kid.payments.where(name: "TASKA BOOKING").where(taska_id: @taska.id).where(paid: false)).present?
      bill.last.destroy
    end
    @kid.taska_id = nil
    if @kid.save
      flash[:success] = "Children has been successfully removed"
    else
      flash[:danger] = "Unsuccessful. Please try again"
    end
    
    redirect_to unreg_kids_path(@taska)
  end

  def child_bill_index
    @taska = Taska.find(params[:id])
    @kid = Kid.find(params[:kid])
    @kid_bills = @kid.payments.where(taska_id: @taska.id).order('bill_year DESC').order('paid ASC').order('bill_month DESC')
    render action: "child_bill_index", layout: "dsb-admin-classroom"
  end


  # GET /taskas/1

  # GET /taskas/1.json
  def show
    # ada kt bawah func set_taska
    @admin_taska = current_admin.taskas
    @unregistered_no = @taska.kids.where(classroom_id: nil).count
    #check payment status
    all_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: false)
    all_unpaid.each do |payment|
      if !payment.paid 
        url_bill = "#{ENV['BILLPLZ_API']}bills/#{payment.bill_id}"
        data_billplz = HTTParty.get(url_bill.to_str,
                :body  => { }.to_json, 
                            #:callback_url=>  "YOUR RETURN URL"}.to_json,
                :basic_auth => { :username => "#{ENV['BILLPLZ_APIKEY']}" },
                :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
        #render json: data_billplz and return
        data = JSON.parse(data_billplz.to_s)
        if data["id"].present? && (data["paid"] == true)
          payment.paid = data["paid"]
          payment.save
        end
      end
    end
    @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: false)
    @taska_expense = @taska.expenses.where(month: $my_time.month).where(year: $my_time.year).order('CREATED_AT DESC')
    session[:taska_id] = @taska.id
    session[:taska_name] = @taska.name  
    render action: "show", layout: "dsb-admin-overview" 
  end

  def sms_reminder
    @taska = Taska.find(params[:id])
    @payment = Payment.find(params[:bill])
    @kid = Kid.find(params[:kid])
    @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_KEY"])
      @client.messages.create(
        to: "+6#{@kid.ph_1}#{@kid.ph_2}",
        from: ENV["TWILIO_PHONE_NO"],
        body: "Reminder from #{@taska.name.upcase}. Please click here <#{bill_view_url(payment: @payment.id, kid: @kid.id, taska: @taska.id)}> to payment."
      )
    @payment.reminder = true
    @payment.save
    flash[:success] = "SMS reminder send to +6#{@kid.ph_1}#{@kid.ph_2}"
    if params[:account].present?
      redirect_to bill_account_path(@taska, 
                                    month: params[:month],
                                    year: params[:year],
                                    paid: false)
    else
      redirect_to unpaid_index_path(@taska)
    end
  end

  def bill_account
    @taska = Taska.find(params[:id])
    if params[:month] == "0"
      @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: params[:paid]).where(bill_year: params[:year]).order('bill_month ASC')
    else
      @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: params[:paid]).where(bill_month: params[:month]).where(bill_year: params[:year])
      #@kid_all_bills = @taska.payments.where.not(name: "TASKA PLAN").order('bill_year ASC').order('bill_month ASC')
    end
    render action: "bill_account", layout: "dsb-admin-account" 
  end

  def unpaid_index
    @taska = Taska.find(params[:id])
    @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: false).order('bill_year ASC').order('bill_month ASC')
    @kid_all_bills = @taska.payments.where.not(name: "TASKA PLAN").order('bill_year ASC').order('bill_month ASC')
    render action: "unpaid_index", layout: "dsb-admin-overview" 
  end

  def sms_reminder_all
    @taska = Taska.find(params[:id])
    if params[:account].present?
      if params[:month] == "0"
        @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: false).where(reminder: false).where(bill_year: params[:year])
      else
        @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: false).where(reminder: false).where(bill_year: params[:year]).where(bill_month: params[:month])
      end
    else
      @kid_unpaid = @taska.payments.where.not(name: "TASKA PLAN").where(paid: false).where(reminder: false)
    end
    @kid_unpaid.each do |bill|
      @kid = bill.kids.first
      @client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_KEY"])
      @client.messages.create(
        to: "+6#{@kid.ph_1}#{@kid.ph_2}",
        from: ENV["TWILIO_PHONE_NO"],
        body: "Reminder from #{@taska.name.upcase}. Please click here <#{bill_view_url(payment: @payment.id, kid: @kid.id, taska: @taska.id)}> to payment."
      )
      bill.reminder = true
      bill.save
    end
    flash[:success] = "SMS reminders sent"
    if params[:account].present?
      redirect_to bill_account_path(@kid.taska, 
                                    month: params[:month],
                                    year: params[:year],
                                    paid: false)
    else
      redirect_to unpaid_index_path(@taska)
    end
  end

  def unpaid_xls
    @taska = Taska.find(params[:id])

    if params[:month].present? && params[:year].present?
      if params[:paid] == "false"
        if params[:month] == "0"
          @bills = @taska.payments.where.not(name: "TASKA PLAN").where(bill_year: params[:year]).where(paid: params[:paid]).order('bill_month ASC')
        else
          @bills = @taska.payments.where.not(name: "TASKA PLAN").where(bill_month: params[:month]).where(bill_year: params[:year]).where(paid: params[:paid])
        end
      else
        if params[:month] == "0"
          @bills = @taska.payments.where.not(name: "TASKA PLAN").where(bill_year: params[:year]).order('bill_month ASC')
        else
          @bills = @taska.payments.where.not(name: "TASKA PLAN").where(bill_month: params[:month]).where(bill_year: params[:year])
        end
      end
    else
      if params[:paid] == "false"
        @bills = @taska.payments.where.not(name: "TASKA PLAN").where(paid: params[:paid]).order('bill_year ASC').order('bill_month ASC')
      else
        @bills = @taska.payments.where.not(name: "TASKA PLAN").order('bill_year ASC').order('bill_month ASC')
      end
    end

    respond_to do |format|
      #format.html
      format.xlsx{
        response.headers['Content-Disposition'] = 'attachment; filename="download.xlsx"'
      }
    end
  end

  def pl_xls
    @taska = Taska.find(params[:id])
    if params[:month] == "0"
      @taska_expenses = @taska.expenses.where(year: params[:year]).order('month ASC')
      @taska_bills = @taska.payments.where.not(name: "TASKA PLAN").where(bill_year: params[:year])
    else
      @taska_expenses = @taska.expenses.where(month: params[:month]).where(year: params[:year])
      @taska_bills = @taska.payments.where.not(name: "TASKA PLAN").where(bill_month: params[:month]).where(bill_year: params[:year])
    end
      
    respond_to do |format|
      #format.html
      format.xlsx{
        response.headers['Content-Disposition'] = 'attachment; filename="download.xlsx"'
      }
    end
  end

  def plrpt_xls
    @taska = Taska.find(params[:id])
    @taska_expense = @taska.expenses.where(year: params[:year]).order('month ASC')
    @taska_payments = @taska.payments.where.not(name: "TASKA PLAN").where(bill_year: params[:year]) 
      
    respond_to do |format|
      #format.html
      format.xlsx{
        response.headers['Content-Disposition'] = 'attachment; filename="download.xlsx"'
      }
    end
  end

  def taskateachers
    @taskateachers = @taska.teachers

  end

  def taskateachers_classroom
    @taskateachers = @taska.teachers
  end

  def classrooms_index
    @taska_classrooms = @taska.classrooms
    @taska_extras = @taska.extras.order('name ASC')
    render action: "classrooms_index", layout: "dsb-admin-classroom" 
  end

  def children_index
    @taska_classrooms = @taska.classrooms
  end

  # GET /taskas/new
  def new
    @taska = Taska.new
    @taska.fotos.build
  end

  # GET /taskas/1/edit
  def edit
    @fotos = @taska.fotos
  end

  # POST /taskas
  # POST /taskas.json
  def create
    @taska = Taska.new(taska_params)
    @taska.expire = $my_time + 13.months
    if @taska.save
      taska_admin1 = TaskaAdmin.create(taska_id: @taska.id, admin_id: current_admin.id)
      if current_admin != Admin.first
        taska_admin2 = TaskaAdmin.create(taska_id: @taska.id, admin_id: Admin.first.id)
      end
      flash[:notice] = "Taska was successfully created"
      redirect_to create_bill_taska_path(id: @taska)
    else
      render :new 
      
    end
    
  end

  def update_bank
    @taska = Taska.find(params[:id])
    @taska.bank_name = params[:bank_name]
    @taska.acc_name = params[:acc_name]
    @taska.acc_no = params[:acc_no]
    @taska.ssm_no = params[:ssm_no]
    if @taska.save
        flash[:success] = "Taska was successfully updated"
        redirect_to create_billplz_bank_path(id: @taska.id)
    else
        flash[:danger] = "Update unsuccessfull. Please try again"
    end
    #redirect_to edit_taska_path(@taska)

  end

  # PATCH/PUT /taskas/1
  # PATCH/PUT /taskas/1.json
  def update
      if @taska.update(taska_params)
        flash[:success] = "Taska was successfully updated"
        #if @taska.bank_status == nil 
          #redirect_to create_billplz_bank_path(id: @taska.id)
        #else
          redirect_to taska_path(@taska)
        #end
        #format.html { redirect_to @taska, notice: 'Taska was successfully updated.' }
        #format.json { render :show, status: :ok, location: @taska }
      else
        flash[:success] = "Update unsuccessfull. Please try again"
        format.html { render :edit }
        #format.json { render json: @taska.errors, status: :unprocessable_entity }
      end
    
  end

  # DELETE /taskas/1
  # DELETE /taskas/1.json
  def destroy
    @taska.destroy
    # respond_to do |format|
    #   format.html { redirect_to taskas_url, notice: 'Taska was successfully destroyed.' }
    #   format.json { head :no_content }
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_taska
      @taska = Taska.find(params[:id])
    end

    def set_all
    @teacher = current_teacher
    @parent = current_parent
    @admin = current_admin  
    @owner = current_owner
  end

    # Never trust parameters from the scary internet, only allow the white list through.
    def taska_params
      params.require(:taska).permit(:name,
                                    :email,
                                    :phone_1,
                                    :phone_2,
                                    :address_1,
                                    :address_2,
                                    :city,
                                    :states,
                                    :postcode,
                                    :supervisor,
                                    :bank_name,
                                    :acc_no,
                                    :acc_name,
                                    :ssm_no,
                                    :plan,
                                    :booking,
                                    :discount,
                                    fotos_attributes: [:foto, :picture, :foto_name]  )
    end
    def taska_params_bank
      params.require(:taska).permit(:bank_name,
                                    :acc_no,
                                    :acc_name,
                                    :ssm_no)
    end

    def check_admin
      same = false
      @taska.admins.each do |admin|
        if admin == current_admin
          same = true
        end
      end
      if !same
        flash[:danger] = "You dont have access"
        redirect_to admin_index_path
      end
    end
end
