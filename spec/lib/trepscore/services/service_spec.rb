require 'spec_helper'

class TestService < TrepScore::Services::Service
  maintained_by github: 'ryanfaerman'

  required do
    string :token
  end

  oauth(provider: :noop, scope: 'noop') do |response, params|
    {
      foo: response[:foo],
      bar: params[:bar]
    }
  end

  def call(*)
    0
  end

  def test
    true
  end
end

describe TrepScore::Services::Service do
  let(:range1) { Date.new(2014, 9, 1)..Date.new(2014, 9, 7) }
  let(:range2) { Date.new(2014, 9, 8)..Date.new(2014, 9, 14) }

  let(:data) { { 'token' => 'foo' } }
  let(:symbols_data) { { token: 'foo' } }

  context '.validate' do
    it 'works with string keys' do
      expect(TestService.validate(data)).to be_empty
    end

    it 'works with symbol keys' do
      expect(TestService.validate(symbols_data)).to be_empty
    end

    it 'catches missing required fields' do
      expect(TestService.validate).not_to be_empty
    end
  end

  context '.validate!' do
    it 'works with string keys' do
      expect { TestService.validate!(data) }.not_to raise_error
    end

    it 'works with symbol keys' do
      expect { TestService.validate!(symbols_data) }.not_to raise_error
    end

    it 'catches missing required fields' do
      expect { TestService.validate! }.to raise_error(TrepScore::ConfigurationError)
    end
  end

  context '.ready?' do
    it 'returns false when missing keys' do
      expect(TestService.ready?(data)).to be_falsey
    end

    let(:oauth_data) { data.merge({foo: 123, 'bar' => 123}) }

    it 'returns true when has keys' do
      expect(TestService.ready?(oauth_data)).to be_truthy
    end
  end

  context '.call' do
    it 'works with a single date range for the period' do
      expect(TestService.call(period: range1, data: data)).to eq(range1 => 0)
    end

    it 'works with an array of date ranges for the period' do
      expect(TestService.call(period: [range1, range2], data: data)).to eq(range1 => 0, range2 => 0)
    end

    it 'works with symbol keys' do
      expect(TestService.call(period: range1, data: symbols_data)).to eq(range1 => 0)
    end

    it 'validates required data fields' do
      expect { TestService.call(period: range1) }.to raise_error(TrepScore::ConfigurationError)
    end
  end

  context '.test' do
    it 'works with string keys' do
      expect(TestService.test(data)).to be_truthy
    end

    it 'works with symbol keys' do
      expect(TestService.test(symbols_data)).to be_truthy
    end

    it 'validates required data fields' do
      expect { TestService.test }.to raise_error(TrepScore::ConfigurationError)
    end
  end

  context '.maintainers' do
    it 'works' do
      expect(TestService.maintainers.first.value).to eq 'ryanfaerman'
    end
  end
end
