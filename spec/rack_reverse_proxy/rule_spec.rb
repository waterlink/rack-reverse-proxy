require "spec_helper"

module RackReverseProxy
  RSpec.describe Rule do
    describe '#get_uri' do
      context 'with path' do
        it 'accepts URLs with square brackets' do
          rule = RackReverseProxy::Rule.new('/test', 'http://example.com')

          uri = rule.get_uri('/test/[id]', {}, nil, nil)

          expect(uri.to_s).to eq 'http://example.com/test/[id]'
        end
      end

      context 'with substitutions' do
        it 'accepts URLs with square brackets' do
          rule = RackReverseProxy::Rule.new(%r{^/test/(.*)}, 'http://example.com/test/$1')

          uri = rule.get_uri('/test/[id]', {}, nil, nil)

          expect(uri.to_s).to eq 'http://example.com/test/[id]'
        end
      end

      context 'with custom url' do
        it 'accepts URLs with square brackets' do
          rule = RackReverseProxy::Rule.new(%r{^/test/(.*)})

          expect_any_instance_of(RackReverseProxy::Rule::Matches).to receive(:custom_url).and_return('/test/[id]')

          uri = rule.get_uri('/test/[id]', {}, nil, nil)

          expect(uri.to_s).to eq '/test/[id]'
        end
      end
    end
  end
end
