require 'lib/models'
require 'csv'

count = 0

CSV::Reader.parse(File.open('data/2009Q4.csv', 'rb')) do |row|
#     2009Q4 Columns:
#     0: Directorate
#     1: Updated
#     2: TransNo
#     3: Service
#     4: Cost Centre
#     5: Supplier Name
#     6: Amount excl vat
#     7: Type

    count += 1
    
    if (count > 4) # skip first four lines that don't contain data
  
      p row
      
      directorate = Directorate.first_or_create(:name => row[0].strip)
      service = Service.first_or_create(:name => row[3].strip)
      supplier = Supplier.first_or_create(:name => row[5].strip)
      
      payment = Payment.first_or_create(
        'trans_no' => row[2],
        'directorate' => directorate,
        'service' =>  service,
        'supplier' => supplier,
        'cost_centre' => row[4].strip,
        'amount' => row[6].strip.gsub(/,/, ''),
        'd' => row[1],
        'tyype' => row[7].strip
      )
  
      unless payment.save
        puts "ERROR: Failed to save payment"
        payment.errors.each do |e|
          puts e
        end
      end
  end
end
