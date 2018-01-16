require 'net/ftp'

namespace :import do
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
      a.save!
    end

    upper_bill_files.each do |file|
      bill_data = JSON.parse(File.read(Rails.root.join('lib', 'import', '2016', 'upper', file)))
      a = Bill.new
      a.bill_id = bill_data['bill_id']
      a.openstate_id = bill_data['id']
      a.title = bill_data['title']
      a.data = bill_data
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
    download_files(download_urls)
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
        parsed_text.css('html > body > p > font[face="Book Antiqua"] text()').wrap('<p>')
        processed_bill_text['Text'] = parsed_text.css('html > body > p > font[face="Book Antiqua"]').inner_html
        processed_bill_text['url'] = version['url']
        # binding.pry if processed_bill_text['Number'].try(:include?, '5341')
        if processed_bill_text['Text'].match(/\(<\/p>[\n]<i><p>(Effective\s{1}\w+\s\d+,\s\d+)<\/p><\/i><p>\)(:<\/p>)?/)
          replacement = '<p>' + processed_bill_text['Text'].match(/\(<\/p>[\n]<i><p>(Effective\s{1}\w+\s\d+,\s\d+)<\/p><\/i><p>\)(:<\/p>)?/)[1] + '</p>'
          processed_bill_text['Text'].gsub!(/\(<\/p>[\n]<i><p>(Effective\s{1}\w+\s\d+,\s\d+)<\/p><\/i><p>\)(:<\/p>)?/, replacement)
        end
        every_bill_version << processed_bill_text
        # TODO: Figure out how to process and save alternate format by identifying it.
      end
      bill.text = every_bill_version
      bill.save
    end
  end

  private

  def download_files(urls)
    puts "File count: #{urls.count}"
    parsed_uri = URI.parse(urls.first)
    BasicSocket.do_not_reverse_lookup = true
    ftp = Net::FTP.new(parsed_uri.hostname, 'anonymous', 'guest')
    urls.each do |url|
      begin
        ftp.getbinaryfile(URI.parse(url).path, Rails.root.join('tmp', 'bills', File.basename(URI.parse(url).path)))
        print '.'
      rescue Net::FTPPermError => e
        puts "warning: can't download #{File.basename(file).to_s} from the remote server (#{e.message.tr("\n","")})."
        next
      end
    end
    ftp.close
  end
end
