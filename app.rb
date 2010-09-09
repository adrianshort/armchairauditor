require 'rubygems'
require 'sinatra'
require 'sinatra-helpers/haml/partials'
require 'haml'
require 'lib/models'

SETTING = Setting.first # Could also do this with Sinatra filters before/do

PAYMENTS_FILTER_MIN = 1000

helpers do
  def commify(amount)
    amount.to_s.reverse.gsub(/(\d\d\d)(?=\d)(?!\d*\.)/,'\1,').reverse
  end
  
  def yesno(boolean)
    boolean == true ? 'Yes' : 'No'
  end
  
  def nicedate(d)
    d.strftime("%d %b %Y")
  end
  
end

get '/' do
  @directorates = Directorate.all( :order => ['name'] )
  @payments_count = Payment.count
  @suppliers_count = Supplier.count 
  @services_count = Service.count
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
  @count = @supplier.payments.size # Payment.count(:supplier_id => @supplier.id) ?
  @avg = @supplier.payments.avg(:amount)
  @max = @supplier.payments.max(:amount)
  @min = @supplier.payments.min(:amount)
  @d_start = @supplier.payments.min(:d)
  @d_end = @supplier.payments.max(:d)
  haml :supplier
end

get '/suppliers/?' do
  @suppliers = Supplier.all( :order => ['name'] )
  haml :suppliers
end

get '/services/:slug/payments.csv' do
  @service = Service.first(:slug => params[:slug])

 headers "Content-Disposition" => "attachment;filename=service-#{@service.slug}.csv",
    "Content-Type" => "application/octet-stream"

  result = "Date,Ref.,URL,Directorate,Supplier,Amount ex. VAT\n"

  for payment in @service.payments
    result += "#{payment.d.strftime("%d %b %Y")},#{payment.id},#{payment.url},\"#{payment.service.directorate.name}\",#{payment.supplier.name},#{sprintf("%0.2f", payment.amount)}\n"
  end

  result
  
end

get '/services/:slug.json' do
  @service = Service.first(:slug => params[:slug])
  headers "Content-Type" => "application/json"
  @service.to_json(:relationships => { :payments => { :include => :all }, :directorate => { :include => :all } })
end

get '/services/:slug' do
  @service = Service.first(:slug => params[:slug])
  @total = @service.payments.sum(:amount)
  @count = @service.payments.size
  @avg = @service.payments.avg(:amount)
  @max = @service.payments.max(:amount)
  @min = @service.payments.min(:amount)
  @d_start = @service.payments.min(:d)
  @d_end = @service.payments.max(:d)
  
  @results = repository(:default).adapter.query("
    SELECT s.name AS supplier_name, s.slug AS supplier_slug, SUM(p.amount) AS total
    FROM payments p, suppliers s
    WHERE p.supplier_id = s.id
    AND p.service_id = #{@service.id}
    GROUP BY s.name, s.slug
    ORDER BY total DESC")

  haml :service
end

get '/services/:slug/payments' do
  @FILTER_VALUES = %w[ 500 1000 2500 5000 10000 20000 ]
  @service = Service.first(:slug => params[:slug])
  # payments_filter_min cookie persists user selection of filter value
  unless @min = request.cookies["payments_filter_min"]
    @min = PAYMENTS_FILTER_MIN
    response.set_cookie(
      "payments_filter_min",
      { :value => @min, :expires => Time.now + (60 * 24 * 60 * 60) }
    )  # 60 days
  end
  @payments = Payment.all(:service_id => @service.id, :amount.gte => @min, :order => [ 'd' ])
  @total = @payments.sum(:amount)
  haml :servicepayments
end

get '/services/:slug/paymentsdetail' do
  @service = Service.first(:slug => params[:slug])
  min = PAYMENTS_FILTER_MIN
  if params[:min].to_i > 0
    min = params[:min].to_i
  end
  @payments = Payment.all(:service_id => @service.id, :amount.gte => min, :order => [ 'd' ])
  @total = @payments.sum(:amount)
  haml :servicepaymentsdetail, :layout => false
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

get '/scoreboard.csv' do
  halt 404
  @councils = Council.all( :order => ['name'] )
  labels = %w[
    id
    created_at
    updated_at
    name
    slug
    url
    data_url
    open_licence
    machine_readable
    start_d
    end_d
  ]
  headers "Content-Disposition" => "attachment;filename=armchair-auditor-scoreboard.csv",
    "Content-Type" => "text/csv"
  output = ""
  for council in @councils
    output += "#{council.id},#{council.created_at.strftime("%d %b %Y")},#{council.updated_at.strftime("%d %b %Y")},#{council.name},#{council.slug},#{council.url},#{council.data_url},#{council.open_licence},#{council.machine_readable},#{council.start_d.strftime("%d %b %Y")},#{council.end_d.strftime("%d %b %Y")}\n"
  end
  labels.join(',') + "\n" + output
end

get '/scoreboard' do
  halt 404
  @councils = Council.all( :order => ['name'] )
  haml :scoreboard
end

not_found do
  haml :not_found
end