require 'rubygems'
require 'sinatra'
require 'sinatra-helpers/haml/partials'
require 'haml'
require 'lib/models'


get '/' do
  @directorates = Directorate.all( :order => ['name'] )
  haml :home
end

get '/directorates/:slug' do
  @directorate = Directorate.first(:slug => params[:slug])
  @total = @directorate.payments.sum(:amount)
  haml :directorate
end

get '/suppliers/:slug.csv' do
  @supplier = Supplier.first(:slug => params[:slug])

 headers "Content-Disposition" => "attachment;filename=supplier-#{@supplier.slug}.csv",
    "Content-Type" => "application/octet-stream"

  result = "Date,Ref.,Trans No,Directorate,Service,Amount ex. VAT\n"

  for payment in @supplier.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.id},#{payment.trans_no},\"#{payment.directorate.name}\",#{payment.service.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/suppliers/:slug' do
  @supplier = Supplier.first(:slug => params[:slug])
  @total = @supplier.payments.sum(:amount)
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

  result = "Date,Ref.,Trans No,Directorate,Supplier,Amount ex. VAT\n"

  for payment in @service.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.id},#{payment.trans_no},\"#{payment.directorate.name}\",#{payment.supplier.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/services/:slug' do
  @service = Service.first(:slug => params[:slug])
  @total = @service.payments.sum(:amount)
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