require 'lib/models'

for supplier in Supplier.all
  supplier.slug = Supplier.slugify(supplier.name)
  supplier.save!
end

for service in Service.all
  service.slug = Service.slugify(service.name)
  service.save!
end

for directorate in Directorate.all
  directorate.slug = Directorate.slugify(directorate.name)
  directorate.save!
end
