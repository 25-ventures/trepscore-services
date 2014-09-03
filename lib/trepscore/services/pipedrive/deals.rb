class Pipedrive::Deals < Pipedrive::Base
  def prepare_options(options = {})
    filter_name = options.delete(:filter)
    if filter_name.present?
      filter = resource(:filters)[filter_name]
      if filter.present?
        options[:params] = (options[:params]||{}).merge({filter_id: filter[:id]})
      end
    end

    options
  end

end