require 'spec_helper'

module LIFX
  describe LightCollection do
    subject(:collection) { LightCollection.new(context: context) }

    let(:context) { double(:context).as_null_object }

    describe '#with_label' do
      let(:light) { double(:light, label: 'Test') }

      before { collection.stub(lights: [light]) }

      shared_examples 'returning the matching Light' do
        it 'returns the first light with a matching label' do
          expect(collection.with_label(label)).to be light
        end
      end

      context 'when the given label is a String' do
        let(:label) { 'Test' }
        it_behaves_like 'returning the matching Light'
      end

      context 'when the given label is a Regexp' do
        let(:label) { /Test/ }
        it_behaves_like 'returning the matching Light'
      end

      context 'when the label is an object responding to match' do
        let(:label) { double(:label, match: true) }
        it_behaves_like 'returning the matching Light'
      end

      context 'when no light matches' do
        let(:light) { double(:light, label: 'Other') }

        it 'returns nil' do
          expect(collection.with_label('Test')).to be_nil
        end
      end
    end
  end
end
