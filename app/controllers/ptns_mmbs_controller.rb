class PtnsMmbsController < ApplicationController
	before_action :set_all

	def mmbxls
		@ptnsmmbs = PtnsMmb.where(id: params[:ids])
		respond_to do |format|
    	#format.html
    	format.xlsx{
  								response.headers['Content-Disposition'] = 'attachment; filename="Senarai Ahli PTNS.xlsx"'
			}
  	end
	end

	def bulkupd
		flash[:success] = "Maklumat Ahli Dikemaskini"
		mmbs = params[:ans]
		mmbs.each do |k,v|
			pt = PtnsMmb.find(k)
			pt.stat = v["stat"]
			pt.statdl = v["statdl"]
			pt.save
		end
		redirect_to request.referrer
	end

	def mmbprof
		@mmb = PtnsMmb.find(params[:id])
		@inst = true
		@inst = false unless @mmb.tp == "AHLI INSTITUSI"
		render action: "mmbprof", layout: "eip"
	end

	def daftarahli
		@ptnsmmb = PtnsMmb.new
		@fotos = @ptnsmmb.fotos.build
	end

	def create
		@ptnsmmb = PtnsMmb.new(ptnsmmb_params)
		if PtnsMmb.where(icf: @ptnsmmb.icf).present?
			flash[:danger] = "DATA ANDA SUDAH DIDAFTARKAN DALAM SISTEM KAMI"	
		else
			idh = {"AHLI BIASA" => "AB", "AHLI SEUMUR HIDUP" => "AH", "AHLI INSTITUSI" => "AI"}
			@ptnsmmb.stat = "Proses Pengesahan"
			@ptnsmmb.newreg = true
			@ptnsmmb.save
			@ptnsmmb.mmbid = "PTNS-#{idh[@ptnsmmb.tp]}-#{@ptnsmmb.id.to_s.rjust(4,"0")}"
			@ptnsmmb.save
			#SEND EMAIL
			url = edit_ptns_mmb_url(id: @ptnsmmb.id)
			puts url
			subject = "Pendaftaran #{@ptnsmmb.name} Diterima"
			to = @ptnsmmb.email
			cc1 = ENV['CC1']
			cc2 = ENV['CC2']
			body = "
				Terima kasih kerana mendaftar sebagai ahli <b>Persatuan Taska Negeri Selangor</b> <br><br>
				Pihak kami telah menerima pendaftaran anda dan akan menjalankan proses verifikasi.
				Sila semak semula status keahlian anda selepas 24 Jam. <br><br>
				Untuk sebarang pertanyaan, sila hubungi Setiausaha Kehormat PTNS.<br><br>

				Untuk kemaskini maklumat pendaftaran anda, sila <a href='#{url}'>KLIK DISINI</a><br><br>

				Terima kasih. 

			"
			send_email(subject,to,cc1,cc2,body)
			flash[:notice] = "Pendaftaran Berjaya dan Sedang Diproses untuk Proses Pengesahan oleh Admin. Anda boleh membuat Semakan Pendaftaran Selepas 24 Jam."
		end	
		redirect_to checkmmb_path(icf: @ptnsmmb.icf)
	end

	def edit
		@ptnsmmb = PtnsMmb.find(params[:id])
	end

	def update
		@ptnsmmb = PtnsMmb.find(params[:id])
		if @ptnsmmb.update(ptnsmmb_params)
			# newic="#{@ptnsmmb.ic1}#{@ptnsmmb.ic2}#{@ptnsmmb.ic3}"
			# @ptnsmmb.icf=newic
			@ptnsmmb.save
			flash[:notice] = "Maklumat anda telah dikemaskini"
			redirect_to checkmmb_path(icf: @ptnsmmb.icf)
			
		else
			render 'edit'
		end
	end

	def checkmmb
		if params[:icf].blank?
			flash[:danger] = "Sila Masukkan No MyKad atau No JKM"
			redirect_to root_path and return
		end
		if (pt=PtnsMmb.where(icf: params[:icf])).present?
			mmb = pt.last
			acv = check2_bill(mmb.id)
			@mmb = PtnsMmb.find(mmb.id)
			@exs = true
			@inst = true
			@inst = false unless @mmb.tp == "AHLI INSTITUSI"
			txt = "Data anda ada dalam rekod kami"
			#QRCODE
			qrcode = RQRCode::QRCode.new(checkmmb_url(icf: @mmb.icf))
			@svg = qrcode.as_svg(
			  offset: 0,
			  color: '000',
			  backgroundcolor: 'white',
			  shape_rendering: 'crispEdges',
			  module_size: 5,
			  standalone: true
			)

			png = qrcode.as_png(
			  bit_depth: 1,
			  border_modules: 4,
			  color_mode: ChunkyPNG::COLOR_GRAYSCALE,
			  color: 'black',
			  file: nil,
			  fill: 'white',
			  module_px_size: 6,
			  resize_exactly_to: false,
			  resize_gte_to: false,
			  size: 200
			)
			if params[:prt].present?
				render action: "checkmmb", layout: "eip"
			end
		else
			@exs = false
			#flash[:notice] = "Data anda tiada dalam rekod. Sila daftar dibawah."
		end
	end

	


# ********** OLD PTNS *****************

	def regedit
		@ptnsmmb = PtnsMmb.find(params[:id])
	end

	def regupd
		@ptnsmmb = PtnsMmb.find(params[:id])
		if @ptnsmmb.update(ptnsmmb_params)
			flash[:success] = "Kemaskini Berjaya"
		else
			flash[:danger] = "Tidak berjaya. Sila cuba lagi"
		end
		redirect_to reg_list_path(evid: @ptnsmmb.tp)
	end

	def reg_event
		@ptnsmmb = PtnsMmb.new
	end

	def reg_cfm
		@ptnsmmb = PtnsMmb.new(ptnsmmb_params)
		if PtnsMmb.where(ic1: @ptnsmmb.ic1,ic2:@ptnsmmb.ic2,ic3:@ptnsmmb.ic3,tp: @ptnsmmb.tp).present?
			flash[:danger] = "PENDAFTARAN TELAH DIBUAT. TERIMA KASIH"
		else
			if @ptnsmmb.save
				flash[:success] = "PENDAFTARAN ANDA BERJAYA #{@ptnsmmb.name}"
			else
				flash[:warning] = "PENDAFTARAN TIDAK BERJAYA. SILA CUBA LAGI"
			end
		end
		redirect_to reg_event_path(evid: @ptnsmmb.tp)

	end

	def reg_list
		@ptnsmmbs = PtnsMmb.where(tp: params[:evid])
	end

	def reg_listxls
		@ptnsmmbs = PtnsMmb.where(tp: params[:evid])
		respond_to do |format|
      #format.html
      format.xlsx{
                  response.headers['Content-Disposition'] = 'attachment; filename="Senarai Pendaftaran.xlsx"'
      }
    end
	end

	def mmblist_xls
		if params[:tp] == "ptns"
			@clb = "PERSATUAN TASKA NEGERI SELANGOR"
		elsif params[:tp] == "kprm"
			@clb = "KELAB REKREASI PENGASUH MALAYSIA"
		end
		@allmmb = PtnsMmb.where(tp: params[:tp])
		respond_to do |format|
      #format.html
      format.xlsx{
                  response.headers['Content-Disposition'] = 'attachment; filename="SENARAI AHLI.xlsx"'
      }
    end
	end
	
	def new
		@ptnsmmb = PtnsMmb.new
		@ptnsmmb.fotos.build
	end

	

	def after_reg
	end

	def find_ptns
    if params[:ic1].blank?
      flash.now[:danger] = "Maklumat tidak lengkap"
    else
    	icf = "#{params[:ic1]}#{params[:ic2]}#{params[:ic3]}"
      @ptns_find = PtnsMmb.where(icf: icf, tp: params[:tp])
      flash.now[:danger] = "Tiada rekod. Sila daftar di ruangan dibawah" unless @ptns_find.present?
    end
    respond_to do |format|
      format.js { render partial: 'ptns_mmbs/result' } 
    end
  end

  def list_ptns
  	passw ={
  		"ptns"=>"abc345",
  		"kprm"=>"abc123"
  	}
  	@tp=params[:tp]
  	if @tp == "ptns"
  		@clb = "PERSATUAN TASKA NEGERI SELANGOR"
  	elsif @tp == "kprm"
  		@clb = "KELAB REKREASI PENGASUH MALAYSIA"
  	end
  	if params[:pw] == passw[@tp]
  		@pw = true
  	else
  		@pw = false
  	end
  	@all_mmb = PtnsMmb.all.order('created_at ASC').where(tp: @tp)
  end

  def add_expire
  	#params.require(:ptns_mmb).permit(:expire, :mmbid, :id)
  	mmb = PtnsMmb.find(params[:ptns_mmb][:id])
  	mmb.expire = params[:ptns_mmb][:expire]
  	mmb.mmbid = params[:ptns_mmb][:mmbid]
  	pw = params[:ptns_mmb][:pw]
  	tp = params[:ptns_mmb][:tp]
  	if mmb.save
  		flash[:success] = "BERJAYA"
  	else
  		flash[:danger] = "TIDAK BERJAYA"
  	end
  	redirect_to list_ptns_path(pw: pw, tp: tp)
  end

  def add_mmbid
  	params.require(:ptns_mmb).permit(:mmbid, :id)
  	mmb = PtnsMmb.find(params[:ptns_mmb][:id])
  	mmb.mmbid = params[:ptns_mmb][:mmbid]
  	if mmb.save
  		flash[:success] = "BERJAYA"
  	else
  		flash[:danger] = "TIDAK BERJAYA"
  	end
  	redirect_to list_ptns_path
  end

  def mmb_pdf
  	if params[:pdf].present?
  		@pdf = false
  	else
			@pdf = true
		end
		@mmb = PtnsMmb.find(params[:id])
		respond_to do |format|
	 		format.html
	 		format.pdf do
		   render pdf: "(#{@mmb.name})",
		   template: "ptns_mmbs/mmb_pdf.html.erb",
		   #disposition: "attachment",
		   #page_size: "A6",
		   
		   orientation: "portrait",
		   layout: 'pdf.html.erb'
			end
		end
	end

	

	def destroy
	end

	private

	def ptnsmmb_params
     params.require(:ptns_mmb).permit(:name,
																		:dob,
																		:ic1,
																		:ic2,
																		:ic3,
																		:ph1,
																		:ph2,
																		:mmb,
																		:edu,
																		:add1,
																		:add2,
																		:city,
																		:state,
																		:postcode,
																		:ts_name,
																		:ts_add1,
																		:ts_add2,
																		:ts_city,
																		:ts_state,
																		:ts_postcode,
																		:ts_status,
																		:ts_owner,
																		:ts_job,
																		:ts_ph1,
																		:ts_ph2,
																		:email,
																		:icf,
																		:tp,
																		:expire,
																		:gender,
																		fotos_attributes: [:foto, :picture, :foto_name])
   end

   def set_all
		@teacher = current_teacher
		@parent = current_parent
		@admin = current_admin	
		@owner = current_owner
  end


end