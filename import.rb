require 'lib/models'
require 'fastercsv'

# Before running this script with a CSV file, prepare it so:
#   - There is only a single line of column headings on the first line of the file
#   - There are no spaces before or after the column headings
#   - The column headings correspond with the key names in the columns{} hash below
#   - The data starts on line 2

columns = 
  { 
    'Directorate' => nil,
    'Updated'     => nil,
    'Service'     => nil,
    'Supplier'    => nil,
    'Amount'      => nil
   }

directorate_replacements =
  [
    [ "Childrens Services", "Children's Services" ],
    [ "Policy,Performance and Planning", "Policy, Performance and Planning" ]
  ]

service_replacements = 
  [
    [ "Corporate Performance and Developmt", "Corporate Performance and Development" ],
    [ "ISB", "ISB - Individual Schools Budget" ],
    [ "Library and Information Services", "Libraries and Information Services" ],
    [ "On Street Parking", "On-Street Parking" ]
  ]
  
count = 0

if ARGV[0].nil?
  puts "Specify the filename of the CSV file to import on the command line"
  exit
end

date_format = ARGV[1].upcase

if date_format != 'DMY' && date_format != 'MDY'
  puts "Specify the date format as DMY or MDY as the second argument on the command line"
  exit
end

FasterCSV.foreach(ARGV[0]) do |row|

    count += 1
    
    if (count > 1) # skip first line that doesn't contain data
      
      p row
      
      directorate_name = row[columns['Directorate']].strip.gsub(/&/, "and")
      service_name = row[columns['Service']].strip.gsub(/&/, "and")
      supplier_name = row[columns['Supplier']].strip.gsub(/&/, "and")
      
      
      for replacement in directorate_replacements
        if directorate_name == replacement[0]
          directorate_name = replacement[1]
        end
      end
      
      for replacement in service_replacements
        if service_name == replacement[0]
          service_name = replacement[1]
        end
      end
      
      directorate = Directorate.first_or_create(:name => directorate_name)
      directorate.save
      service = Service.first_or_create(:name => service_name, :directorate => directorate)
      service.save
      supplier = Supplier.first_or_create(:name => supplier_name)
      supplier.save
      
      dt = row[columns['Updated']].strip.split('/')

      # Date.new takes YMD params
      if date_format == 'DMY'
        d = Date.new(dt[2].to_i, dt[1].to_i, dt[0].to_i) 
      elsif date_format == 'MDY'
        d = Date.new(dt[2].to_i, dt[0].to_i, dt[1].to_i)
      elsif date_format == 'YMD'
        d = Date.new(dt[0].to_i, dt[1].to_i, dt[2].to_i)
      end
      
      payment = Payment.first_or_new(
        'service' =>  service,
        'supplier' => supplier,
        'amount' => row[columns['Amount']].strip.gsub(/,/, ''),
        'd' => d
      )
  
      unless payment.save
        puts "ERROR: Failed to save payment"
        payment.errors.each do |e|
          puts e
        end
      end
  else
    # Get the column headings
    position = 0

    for column in row
      columns[column] = position
      position += 1
    end
    puts columns.inspect
  end
end
