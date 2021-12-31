desc "mmb_expr"
task mmb_expr: :environment do

	PtnsMmb.all.where(stat: "Aktif").each do |ptn|
	#change status
	ptn.statdl = nil
	ptn.stat = "Keahlian Luput"
	ptn.save

	if ptn.email.present?
		#email
		url = "https://prd-ptns.herokuapp.com/ptns_mmbs/#{ptn.id}/edit?icf=#{ptn.icf}&tp=#{ptn.tp}"
		puts url
		subject = "#{ptn.name} Kemaskini Keahlian PTNS"
		to = ptn.email
		cc1 = ENV['CC1']
		cc2 = ENV['CC2']
		body = "<b>(#{ptn.icf} #{ptn.name})</b>, untuk makluman keahlian Persatuan Taska Negeri Selangor (PTNS) anda akan luput pada 31 Disember 2021.<br><br>
						Anda perlu mengemaskini butiran peribadi dan menjelaskan yuran tahunan sebelum <b>31 Januari 2022</b>.<br><br>
						Sila berbuat klik <a href='#{url}'>KLIK DISINI</a> untuk memperbaharui keahlian anda.<br><br>
						Sila hubungi 03-55107655 (Pejabat PTNS) jika terdapat sebarang pertanyaan.<br><br><br>

						Setiausaha PTNS.

					"
		mail = SendGrid::Mail.new
	  mail.from = SendGrid::Email.new(email: "admin@ptns.my", name: "Persatuan Taska Negeri Selangor")
	  mail.subject = "#{subject}"
	  #Personalisation, add cc
	  personalization = SendGrid::Personalization.new
	  personalization.add_to(SendGrid::Email.new(email: "#{to}"))
	  if cc1.present?
	    personalization.add_cc(SendGrid::Email.new(email: "#{cc1}"))
	  end
	  if cc2.present?
	    personalization.add_cc(SendGrid::Email.new(email: "#{cc2}"))
	  end
	  #personalization.add_bcc(SendGrid::Email.new(email: "mmnr00@gmail.com"))
	  mail.add_personalization(personalization)
	  #add content
	  msg = "<html>
	          <body>
	            #{body}
	          </body>
	        </html>"
	  #sending email
	  mail.add_content(SendGrid::Content.new(type: 'text/html', value: "#{msg}"))
	  sg = SendGrid::API.new(api_key: ENV['SENDGRID_PASSWORD'])
	  @response = sg.client.mail._('send').post(request_body: mail.to_json)
	  #render json: @response and return
	  puts @response.status_code
	 else
	 	puts "no email #{ptn.id}"
	 end

	end
end