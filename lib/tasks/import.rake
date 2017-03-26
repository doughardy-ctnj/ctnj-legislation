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
end
