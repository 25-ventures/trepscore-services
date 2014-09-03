class Pipedrive::Filters < Pipedrive::Base
  
  %w{deals people products organizations}.each do |type|
    define_method type do |*options|
      for_type(type, options.first)
    end
  end

  def for_type(type, options = {})
    type = type.to_sym
    type = :org if type == :organizations

    get (options || {}).merge!({params: {type: type}})
  end

  def [](name_key)
    name = name_key.to_s.humanize
    get.select{|filter| filter['name'] == name}.first
  end

end