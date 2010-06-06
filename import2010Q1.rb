require 'lib/models'
require 'csv'

count = 0

# 2010Q1: 0-Directorate,1-Updated,2-Service,3-Supplier Name,4-Amount excl vat £,5-Type

CSV::Reader.parse(File.open('data/2010Q1.csv', 'rb')) do |row|


    count += 1
    
    if (count > 4) # skip first four lines that don't contain data
  
      p row
      
      directorate = Directorate.first_or_create(:name => row[0].strip)
      service = Service.first_or_create(:name => row[2].strip)
      supplier = Supplier.first_or_create(:name => row[3].strip)
      
      dt = row[1].strip.split('/')
      
      payment = Payment.first_or_create(
        'directorate' => directorate,
        'service' =>  service,
        'supplier' => supplier,
        'amount' => row[4].strip.gsub(/,/, ''),
        'd' => Date.new(dt[2].to_i, dt[1].to_i, dt[0].to_i),
        'tyype' => row[5].strip
      )
  
      unless payment.save
        puts "ERROR: Failed to save payment"
        payment.errors.each do |e|
          puts e
        end
      end
  end
end
