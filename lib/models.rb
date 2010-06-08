require 'rubygems'
# gem "datamapper", "0.9.11"
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-aggregates'

SITE_URL = 'http://armchairauditor.co.uk/'

class Payment
  include DataMapper::Resource
  
  property :id,             Serial
  property :created_at,     DateTime
  property :updated_at,     DateTime
  property :service_id,     Integer,     :required => true
  property :supplier_id,    Integer,     :required => true
  property :amount,         BigDecimal,  :precision => 10, :scale => 2, :required => true # ex VAT
  property :d,              Date,        :required => true # "Updated" in RBWM CSV files
  
  belongs_to :service
  belongs_to :supplier
  has 1, :directorate, { :through => :service }

  def url
    SITE_URL + "payments/" + @id.to_s
  end
end


class Directorate
  include DataMapper::Resource
  
  property :id,           Serial
  property :created_at,   DateTime
  property :updated_at,   DateTime
  property :name,         String, :length => 255, :required => true
  property :slug,         String, :length => 255
  
#   has n, :payments, { :through => :services, :order => ['d'] }
  has n, :services, :order => ['name']
  has n, :suppliers, { :through => :services, :order => ['name'] }

  before :save, :slugify

  def slugify
    @slug = @name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  end
end

class Service
  include DataMapper::Resource
  
  property :id,             Serial
  property :created_at,     DateTime
  property :updated_at,     DateTime
  property :directorate_id, Integer,  :required => true
  property :name,           String,   :length => 255, :required => true
  property :slug,           String,   :length => 255
  
  has n, :payments, :order => ['d']
  has n, :suppliers, { :through => :payments, :order => ['name'] }
  belongs_to :directorate

  before :save, :slugify

  def slugify
    @slug = @name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  end 
end

class Supplier
  include DataMapper::Resource
  
  property :id,         Serial
  property :created_at, DateTime
  property :updated_at, DateTime
  property :name,       String, :length => 255, :required => true
  property :slug,       String, :length => 255
  
  has n, :payments, :order => ['d']
  has n, :services, { :through => :payments, :order => ['name'] }
  has n, :directorates, { :through => :payments }
  
  before :save, :slugify

  def slugify
    @slug = @name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db.sqlite3")
DataMapper.auto_upgrade!
