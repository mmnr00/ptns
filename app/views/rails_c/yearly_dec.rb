PtnsMmb.all.where(id: 206).each do |ptn|
#change status
ptn.statdl = nil
ptn.stat = "Keahlian Luput"
ptn.save
#email
url = "https://prd-ptns.herokuapp.com//ptns_mmbs/#{ptn.id}/edit?icf=#{ptn.icf}&tp=#{ptn.tp}"
puts url
subject = "#{ptn.name} Kemaskini Keahlian PTNS"
to = ptn.email
cc1 = ENV['CC1']
cc2 = ENV['CC2']
body = "Dimaklumakan bawah keahlian PTNS untuk #{ptn.name}(#{ptn.icf}) telah luput pada 31-Dec-2021.<br>
				Untuk mengaktifkan semula keahlian anda, sila <a href='#{url}'>KLIK DISINI</a><br><br>
				Untuk sebarang pertanyaan, sila hubungi Setiausaha Kehormat PTNS.<br><br>

				
				Terima kasih. 

			"
send_email(subject,to,cc1,cc2,body)

end