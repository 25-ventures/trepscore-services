class Pipedrive::Activities < Pipedrive::Base
  def prepare_options(options = {})
    type_name = options.delete(:filter)
    options[:params] = (options[:params]||{}).merge({type: type_name})

    options
  end

  def types
    resource(:activity_types).all
  end
end