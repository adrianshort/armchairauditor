require 'rubygems'
require 'sinatra'
require 'sinatra-helpers/haml/partials'
require 'haml'
require 'lib/models'


get '/' do
  @directorates = Directorate.all
  
#   @results = repository(:default).adapter.query("
#     SELECT  p.name,
#             sum(c.votes_2010) AS votes,
#             p.colour 
#             
#     FROM    parties p,
#             councilcandidates c 
#             
#     WHERE   p.id = c.party_id
#     
#     GROUP BY p.name, p.colour
#     
#     ORDER BY votes desc
#   ;")

# select p.name, count(c.*) AS seats
# FROM parties p, councilcandidates c
# GROUP BY p.id
  
  haml :home
end

get '/directorates/:id' do
  @directorate = Directorate.get(params[:id])
  @total = @directorate.payments.sum(:amount)
  haml :directorate
end

get '/suppliers/:id.csv' do
  @supplier = Supplier.get(params[:id])

 headers "Content-Disposition" => "attachment;filename=supplier#{@supplier.id}.csv",
    "Content-Type" => "application/octet-stream"

  result = "Date,Trans No,Directorate,Service,Amount ex. VAT\n"

  for payment in @supplier.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.trans_no},\"#{payment.directorate.name}\",#{payment.service.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/suppliers/:id' do
  @supplier = Supplier.get(params[:id])
  @total = @supplier.payments.sum(:amount)
  haml :supplier
end

get '/suppliers/?' do
  @suppliers = Supplier.all( :order => ['name'] )
  haml :suppliers
end

get '/services/:id.csv' do
  @service = Service.get(params[:id])

 headers "Content-Disposition" => "attachment;filename=service#{@service.id}.csv",
    "Content-Type" => "application/octet-stream"

  result = "Date,Trans No,Directorate,Supplier,Amount ex. VAT\n"

  for payment in @service.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.trans_no},\"#{payment.directorate.name}\",#{payment.supplier.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/services/:id' do
  @service = Service.get(params[:id])
  @total = @service.payments.sum(:amount)
  haml :service
end

get '/services/?' do
  @services = Service.all( :order => ['name'] )
  haml :services
end

get '/wards/:slug/postcode/:postcode/?' do
  @ward = Ward.first(:slug => params[:slug])
  @postcode = params[:postcode]
  haml :wards
end

get '/wards/:slug/?' do
  @ward = Ward.first(:slug => params[:slug])
  haml :wards
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