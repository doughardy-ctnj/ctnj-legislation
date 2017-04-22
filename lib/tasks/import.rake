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
    Bill.where(text: nil).each do |bill|
      bill.data['versions'].each do |version|
        download_file(version['url'])
      end
    end
  end

  private

  def download_file(url)
    parsed_uri = URI.parse(url)
    BasicSocket.do_not_reverse_lookup = true
    ftp = Net::FTP.new(parsed_uri.hostname, 'anonymous', 'guest')
    begin
      ftp.getbinaryfile(parsed_uri.path, Rails.root.join('lib', 'import', 'bills', File.basename(parsed_uri.path)))
      ftp.close
    rescue Net::FTPPermError => e
      logger.error "warning: can't download #{File.basename(file)} from the remote server (#{e.message.tr("\n","")})."
      ftp.close
      return nil
    end
  end
end
