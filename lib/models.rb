require 'rubygems'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-aggregates'

class Payment
  include DataMapper::Resource
  
  property :id,             Serial
  property :trans_no,       Integer,     :required => false # "TransNo" in RBWM CSV files
  property :directorate_id, Integer,     :required => true
  property :service_id,     Integer,     :required => true
  property :supplier_id,    Integer,     :required => true
  property :cost_centre,    String,      :required => false
  property :amount,         BigDecimal,  :precision => 10, :scale => 2, :required => true # ex VAT
  property :d,              Date,        :required => true # "Updated" in RBWM CSV files
  property :tyype,          String,      :required => true # Capital or Revenue
  
  belongs_to :directorate
  belongs_to :service
  belongs_to :supplier
end


class Directorate
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 255, :required => true
  
  has n, :payments, :order => ['d']
end

class Service
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 255, :required => true
  
  has n, :payments, :order => ['d']
end

class Supplier
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :length => 255, :required => true
  
  has n, :payments, :order => ['d']
  
#   def self.slugify(name)
#     name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
#   end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db.sqlite3")
DataMapper.auto_upgrade!
