require 'lib/models'
require 'fastercsv'

# Before running this script with a CSV file, prepare it so:
#   - There is only a single line of column headings on the first line of the file
#   - There are no spaces before or after the column headings
#   - The column headings correspond with the key names in the columns{} hash below
#   - The data starts on line 2

def slugify(name)
  output = name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  output.gsub(/---/, '-')
end

months = %w[ dummy Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ]

columns = 
  { 
    'Directorate' => nil,
    'Updated'     => nil,
    'Service'     => nil,
    'Supplier'    => nil,
    'Amount'      => nil,
    'Transaction Number' => nil,
   }

directorate_replacements =
  [
  ]

service_replacements = 
  [
  ]
  
count = 0

if ARGV[0].nil?
  puts "Specify the filename of the CSV file to import on the command line"
  exit
end

FasterCSV.foreach(ARGV[0]) do |row|

    count += 1
    
    if (count > 1) # skip first line that doesn't contain data
      
      p row
      
      unless row[columns['Directorate']].nil?
        directorate_name = row[columns['Directorate']].strip.gsub(/&/, "and")
      end
      
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
      
      if directorate_name.nil?
        directorate = nil
      else
        directorate = Directorate.first_or_create(:name => directorate_name, :slug => slugify(directorate_name))
        directorate.save
      end
      
      service = Service.first_or_create(:name => service_name, :directorate => directorate, :slug => slugify(service_name))
      service.save
      
      supplier = Supplier.first_or_create(:name => supplier_name, :slug => slugify(supplier_name))
      supplier.save
      
      dt = row[columns['Updated']].strip.split(' ')
      d = Date.new(dt[2].to_i, months.index(dt[1]), dt[0].to_i)

      # Using Payment.new rather than Payment.first_or_new allows us to create genuine duplicates
      # so don't run the importer more than once with the same set of data
      payment = Payment.new(
        'service' =>  service,
        'supplier' => supplier,
        'amount' => row[columns['Amount']].strip.gsub(/,/, ''),
        'd' => d,
        'transaction_id' => row[columns['Transaction Number']].strip.to_i
      )
  
      unless payment.save # save runs callbacks/hooks, save! doesn't
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
