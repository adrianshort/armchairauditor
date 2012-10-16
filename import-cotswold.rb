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

columns = () 
directorate_column = nil
service_name_column = nil
vendor_name_column = nil
date_column = nil

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

Setting.first_or_create(
  :id => 1,
  :site_name => 'Cotswold District Council Armchair Auditor',
  :site_tagline => 'moinkles',
  :site_url => 'http://cotswold.chard.org/',
  :org_name => 'Cotswolds',
  :org_url => 'http://www.cotswold.gov.uk/',
  :data_url => 'http://www.cotswold.gov.uk/nqcontent.cfm?a_id=13293#files'
)

FasterCSV.foreach(ARGV[0]) do |row|

    count += 1
    
    if (count > 1) # skip first line that doesn't contain data
      
      p row
      
      if not directorate_column.nil?
        directorate_name = row[columns[directorate_column]].strip.gsub(/&/, "and")
        directorate = Directorate.first_or_create(:name => directorate_name, :slug => slugify(directorate_name))
        unless directorate.save
          puts "ERROR: Failed to save directorate"
          puts directorate.errors.inspect
        end
      end
      service_name = row[columns[service_name_column]].strip.gsub(/&/, "and")
      supplier_name = row[columns[vendor_name_column]].strip.gsub(/&/, "and")
      
      
      #for replacement in directorate_replacements
        #if directorate_name == replacement[0]
          #directorate_name = replacement[1]
        #end
      #end
      
      for replacement in service_replacements
        if service_name == replacement[0]
          service_name = replacement[1]
        end
      end
      
      service = Service.first_or_create(:name => service_name, :directorate => directorate, :slug => slugify(service_name))
      unless service.save
        puts "ERROR: Failed to save service"
        puts service.errors.inspect
      end
      supplier = Supplier.first_or_create(:name => supplier_name, :slug => slugify(supplier_name))
      unless supplier.save
        puts "ERROR: Failed to save supplier"
        puts supplier.errors.inspect
      end
      
      if row[columns[date_column]].nil?
	if ARGV[2].nil?
	  puts "ERROR: missing payment dates; specify date on command line"
	  exit
	end
        dt = ARGV[2].strip.split('/')
      else
        dt = row[columns[date_column]].strip.split('/')
      end

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
	puts payment.errors.inspect
        payment.errors.each do |e|
          puts e
        end
      end
  else
    # Get the column headings
    position = 0

    # Annoyingly, CDC has changed its column names, and we want to support
    # both types of file.  Even more annoyingly, directorates aren't
    # specified any more.
    if row.include? 'Vendor Name'
      service_name_column = 'Service Area'
      vendor_name_column = 'Vendor Name'
      date_column = 'Payment Date'

      columns = 
        { 
          'Body name' => nil,
          'Body' => nil,
          'Number' => nil,
          'Invoice Ref.' => nil,
          'Vendor Name' => nil,
          'Expense' => nil,
          'Expense Type' => nil,
          'Cost Centre' => nil,
          'Payment Date' => nil,
          'Amount' => nil,
          'Service Area' => nil,
        }
    else
      directorate_column = 'Service Area Categorisation'
      service_name_column = 'Service Division Categorisation'
      vendor_name_column = 'Supplier Name'
      if row.include? 'Invoice Date'
        date_column = 'Invoice Date'
      else
        date_column = 'Date'
      end

      columns =
        { 
	  'Body Name' => nil,
	  'Body' => nil,
	  'Service Area Categorisation' => nil,
	  'Service Division Categorisation' => nil,
	  'Responsible Unit' => nil,
	  'Expenses type' => nil,
	  'Detailed expenses type' => nil,
	  'Expenses code' => nil,
	  'Narrative' => nil,
	  date_column => nil,
	  'Transaction Number' => nil,
	  'Amount' => nil,
	  'Revenue/Capital' => nil,
	  'Supplier Name' => nil,
	  'Supplier ID' => nil,
	  'Contract ID' => nil,
	  'Notes' => nil
	}
    end

    for column in row
      columns[column] = position
      position += 1
    end
    puts columns.inspect
  end
end
