class Payment
  include DataMapper::Resource
  
  property :id,             Serial
  property :created_at,     DateTime
  property :updated_at,     DateTime
  property :service_id,     Integer,     :required => true
  property :supplier_id,    Integer,     :required => true
  property :amount,         BigDecimal,  :precision => 10, :scale => 2, :required => true # ex VAT
  property :d,              Date,        :required => true # transaction date
  property :transaction_id, Integer      # May not be unique per payment as one transaction could have several payments
  
  belongs_to :service
  belongs_to :supplier
  has 1, :directorate, { :through => :service }

  def url
    SETTING.site_url + "payments/" + @id.to_s
  end
end


class Directorate
  include DataMapper::Resource
  
  property :id,           Serial
  property :created_at,   DateTime
  property :updated_at,   DateTime
  property :name,         String, :length => 255, :required => true
  property :slug,         String, :length => 255, :required => true
  
  has n, :services, :order => ['name']
  has n, :suppliers, { :through => :services, :order => ['name'] }

#   before :save, :slugify
# 
#   def slugify
#     @slug = @name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
#     puts "I've just been slugified"
#   end
end

class Service
  include DataMapper::Resource
  
  property :id,             Serial
  property :created_at,     DateTime
  property :updated_at,     DateTime
  property :directorate_id, Integer
  property :name,           String,   :length => 255, :required => true
  property :slug,           String,   :length => 255, :required => true
  
  has n, :payments, :order => ['d']
  has n, :suppliers, { :through => :payments, :order => ['name'] }
  belongs_to :directorate, :required => false

#   before :save, :slugify
# 
#   def slugify
#     @slug = @name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
#     puts "I've just been slugified"
#   end
end

class Supplier
  include DataMapper::Resource
  
  property :id,         Serial
  property :created_at, DateTime
  property :updated_at, DateTime
  property :name,       String, :length => 255, :required => true
  property :slug,       String, :length => 255, :required => true
  
  has n, :payments, :order => ['d']
  has n, :services, { :through => :payments, :order => ['name'] }
  has n, :directorates, { :through => :payments }
  
#   before :save, :slugify
# 
#   def slugify
#     @slug = @name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').downcase
#   end
end


# This is a singleton. We only use the first row in the settings table.

class Setting
  include DataMapper::Resource
  
  property :id,                   Serial
  property :site_name,            String,   :length => 255, :required => true
  property :site_tagline,         String,   :length => 255
  property :site_url,             String,   :length => 255
  property :org_name,             String,   :length => 255
  property :org_url,              String,   :length => 255
  property :data_url,             String,   :length => 255
  property :disqus_shortname,     String,   :length => 255
  property :google_analytics_id,  String,   :length => 255
end

# DataMapper.setup(:default, ENV['DATABASE_URL'] || "mysql://root@localhost/armchairauditor_sutton")
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db.sqlite3")
DataMapper.auto_upgrade!
