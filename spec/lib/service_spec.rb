require 'trepscore-services'
Service.load_services

Service.services.each do |service|
  describe service do
    it 'implements the call interface' do
      callable =  begin
                    described_class.call
                  rescue NotImplementedError
                    false
                  rescue Service::ConfigurationError
                    true
                  end
      expect(callable).to be_truthy,
        "#{described_class} does not implement the call method"
    end

    it 'complies with its own schema' do
      data = {}
      described_class.schema.each do |type, key|
        data[key.to_s] = case type
                    when :string   then 'foo'
                    when :password then 'bar'
                    when :boolean  then true
                    end
      end

      callable =  begin
                    described_class.call(data: data)
                    true
                  rescue Service::ConfigurationError
                    false
                  end

      expect(callable).to be_truthy,
        "#{described_class} doesn't comply with its own schema"
    end
  end
end
