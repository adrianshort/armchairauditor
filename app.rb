require 'rubygems'
require 'sinatra'
require 'sinatra-helpers/haml/partials'
require 'haml'
require 'lib/models'

get '/' do
  @directorates = Directorate.all( :order => ['name'] )
  @results = repository(:default).adapter.query("SELECT COUNT(*) FROM payments")
  @payments_count = @results[0]
  @results = repository(:default).adapter.query("SELECT COUNT(*) FROM suppliers")
  @suppliers_count = @results[0]  
  @results = repository(:default).adapter.query("SELECT COUNT(*) FROM services")
  @services_count = @results[0]
  haml :home
end

get '/directorates/:slug' do
  @directorate = Directorate.first(:slug => params[:slug])
  haml :directorate
end

get '/suppliers/:slug.csv' do
  @supplier = Supplier.first(:slug => params[:slug])

 headers "Content-Disposition" => "attachment;filename=supplier-#{@supplier.slug}.csv",
    "Content-Type" => "application/octet-stream"

  result = "Date,Ref.,URL,Directorate,Service,Amount ex. VAT\n"

  for payment in @supplier.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.id},#{payment.url},\"#{payment.service.directorate.name}\",#{payment.service.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/suppliers/:slug' do
  @supplier = Supplier.first(:slug => params[:slug])
  @total = @supplier.payments.sum(:amount)
  @count = @supplier.payments.size
  @avg = @supplier.payments.avg(:amount)
  @max = @supplier.payments.max(:amount)
  @min = @supplier.payments.min(:amount)
  haml :supplier
end

get '/suppliers/?' do
  @suppliers = Supplier.all( :order => ['name'] )
  haml :suppliers
end

get '/services/:slug.csv' do
  @service = Service.first(:slug => params[:slug])

 headers "Content-Disposition" => "attachment;filename=service-#{@service.slug}.csv",
    "Content-Type" => "application/octet-stream"

  result = "Date,Ref.,URL,Directorate,Supplier,Amount ex. VAT\n"

  for payment in @service.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.id},#{payment.url},\"#{payment.service.directorate.name}\",#{payment.supplier.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/services/:slug' do
  @service = Service.first(:slug => params[:slug])
  @total = @service.payments.sum(:amount)
  @count = @service.payments.size
  @avg = @service.payments.avg(:amount)
  @max = @service.payments.max(:amount)
  @min = @service.payments.min(:amount)
  
  @results = repository(:default).adapter.query("
    SELECT s.id, s.name AS supplier_name, s.slug AS supplier_slug, SUM(p.amount) AS total
    FROM payments p, suppliers s
    WHERE p.supplier_id = s.id
    AND p.service_id = #{@service.id}
    GROUP BY s.id
    ORDER BY total DESC")

  haml :service
end

get '/services/?' do
  @services = Service.all( :order => ['name'] )
  haml :services
end

get '/payments/:id' do
  @payment = Payment.get(params[:id])
  haml :payment
end

get '/error' do
  haml :error
end

get '/about' do
  haml :about
end

not_found do
  haml :not_found
end