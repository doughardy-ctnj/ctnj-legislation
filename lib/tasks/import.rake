require 'net/ftp'

namespace :import do
  desc 'Latest bill data from Open States API'
  task latest_bill_data: :environment do
    # Should probably run this at 11 p.m. nightly
    last_updated = Bill.order(:open_states_updated_at).last.open_states_updated_at.to_s
    response = Faraday.get "https://openstates.org/api/v1/bills/?state=ct&&apikey=#{Rails.application.secrets.openstates_api_key}&updated_since=#{last_updated}"
    Rails.logger.info 'Open States Download Bill count: ' + JSON.parse(response.body).count.to_s
    JSON.parse(response.body).each do |bill|
      bill_response = Faraday.get "https://openstates.org/api/v1/bills/#{bill['id']}/?apikey=#{Rails.application.secrets.openstates_api_key}"
      bill_data = JSON.parse(bill_response.body)
      a = Bill.find_or_initialize_by(openstate_id: bill_data['id'])
      a.bill_id = bill_data['bill_id']
      a.openstate_id = bill_data['id']
      a.title = bill_data['title']
      a.data = bill_data
      a.open_states_updated_at = Date.parse(bill_data['updated_at'])
      a.text = nil
      a.save
    end
    Rake::Task["import:bill_text"].invoke
    Rake::Task["import:bill_text_to_database"].invoke
  end

  desc 'Import bill data locally'
  task local_bill_data: :environment do
    lower_bill_files = Dir.entries(Rails.root.join('lib', 'import', '2016', 'lower')).reject{ |entry| entry =~ /^\.{1,2}$/ }
    upper_bill_files = Dir.entries(Rails.root.join('lib', 'import', '2016', 'upper')).reject{ |entry| entry =~ /^\.{1,2}$/ }

    lower_bill_files.each do |file|
      bill_data = JSON.parse(File.read(Rails.root.join('lib', 'import', '2016', 'lower', file)))
      a = Bill.new
      a.bill_id = bill_data['bill_id']
      a.openstate_id = bill_data['id']
      a.title = bill_data['title']
      a.data = bill_data
      a.open_states_updated_at = DateTime.parse(bill_data['updated_at'])
      a.save!
    end

    upper_bill_files.each do |file|
      bill_data = JSON.parse(File.read(Rails.root.join('lib', 'import', '2016', 'upper', file)))
      a = Bill.new
      a.bill_id = bill_data['bill_id']
      a.openstate_id = bill_data['id']
      a.title = bill_data['title']
      a.data = bill_data
      a.open_states_updated_at = DateTime.parse(bill_data['updated_at'])
      a.save!
    end
  end

  desc 'Download bill text'
  task bill_text: :environment do
    download_urls = []
    Bill.where(text: nil).each do |bill|
      bill.data['versions'].each do |version|
        next if File.exist?(Rails.root.join('tmp', 'bills', File.basename(version['url'])))
        download_urls << version['url']
      end
    end
    download_files(download_urls) if download_urls.count > 0
  end

  desc 'Import bill text to database'
  task bill_text_to_database: :environment do
    Bill.where(text: nil).each do |bill|
      every_bill_version = []
      bill.data['versions'].each do |version|
        raw_bill_text = File.read(Rails.root.join('tmp', 'bills', File.basename(version['url']))).force_encoding(Encoding::ISO_8859_1)
        next if raw_bill_text.blank?
        parsed_text = Nokogiri::HTML(raw_bill_text)
        processed_bill_text = {}
        # Chamber
        processed_bill_text['Chamber'] = parsed_text.css('tr td p font')[0].text
        # Session
        processed_bill_text['Session'] = parsed_text.css('tr td p font')[2].text
        # LCO Number
        processed_bill_text['LCO Number'] = /LCO No\. \d+/.match(parsed_text.css('tr td p font').text)[0] if /LCO No\. \d+/.match(parsed_text.css('tr td p font').text)
        # Proposed Bill Number (sometimes the barcode string)
        processed_bill_text['Number'] = /Bill No\. \d+/.match(parsed_text.css('tr td p font').text)[0] if /Bill No\. \d+/.match(parsed_text.css('tr td p font').text)
        # Barcode String (not working)
        processed_bill_text['Barcode String'] = parsed_text.css('tr td p font[face="Abri Barcode39Na"]').text
        # Action/Committee
        processed_bill_text['Action'] = parsed_text.css('tr td p font')[5].text
        # Introducers
        processed_bill_text['Introducers'] = []
        parsed_text.css('td[width="275"]').each do |introducer|
          processed_bill_text['Introducers'] << introducer.text.chomp
        end
        # Bill Name
        processed_bill_text['Name'] = parsed_text.css('p font b i')[1].text
        # Bill Text
        processed_bill_text['Text'] = String.new
        parsed_text.css('html > body > p > font[face="Book Antiqua"]').each do |paragraph|
          processed_bill_text['Text'] << '<p>' + paragraph.inner_html + '</p>'
        end
        processed_bill_text['Text'].gsub!(/(<b>|<\/b>)/, "")
        processed_bill_text['Text'].gsub!(/\[/, "<span class=\"remove\">")
        processed_bill_text['Text'].gsub!(/\]/, "</span>")
        processed_bill_text['url'] = version['url']
        every_bill_version << processed_bill_text
      end
      bill.text = every_bill_version
      bill.save
    end
  end


  desc 'Fix funky sponsor names'
  task fix_sponsor_names: :environment do
    Bill.all.each do |bill|
      bill.data['sponsors'].each do |sponsor|
        sponsor['name'].gsub!(/b/,'')
        sponsor['name'].gsub!(/'/,'')
        sponsor['name'].gsub!(/\,/,'')
      end
      bill.save
    end
  end

  private

  def download_files(urls)
    Rails.logger.info "File count: #{urls.count}"
    parsed_uri = URI.parse(urls.first)
    BasicSocket.do_not_reverse_lookup = true
    ftp = Net::FTP.new(parsed_uri.hostname, 'anonymous', 'guest')
    urls.each do |url|
      begin
        ftp.getbinaryfile(URI.parse(url).path, Rails.root.join('tmp', 'bills', File.basename(URI.parse(url).path)))
      rescue StandardError => e
        Rails.logger.error "warning: can't download #{File.basename(file).to_s} from the remote server (#{e.message.tr("\n","")})."
        next
      end
    end
    ftp.close
  end
end
