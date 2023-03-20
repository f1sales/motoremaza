require 'ostruct'

RSpec.describe F1SalesCustom::Hooks::Lead do
  context 'when come from myHonda' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.attachments = []
      lead.product = product
      lead.description = 'REMAZA CENTRO'

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'myHonda'

      source
    end

    let(:product) do
      product = OpenStruct.new
      product.name = ''

      product
    end

    let(:switch_source) { described_class.switch_source(lead) }

    context 'when it comes by robot' do
      it 'returns source name' do
        expect(switch_source).to eq('myHonda')
      end
    end

    context 'when it comes by email' do
      before do
        lead.attachments = ['https://myhonda.force.com/leads/s/lead/00Q4M']
        source.name = 'Email da Honda'
      end

      it 'returns nil source' do
        # expect(switch_source).to be_nil
        expect(switch_source).to eq('Email da Honda')
      end
    end

    context 'when dealership is DAITAN' do
      before { lead.description = 'Concessionária: DAITAN - Código: 1015699' }

      it 'return nil source' do
        expect(switch_source).to be_nil
      end
    end

    context 'when services come in product name' do
      context 'when is Peça' do
        before { lead.description = 'Concessionária: DAITAN - Código: 1015699' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is Agendamento de Serviço' do
        before { product.name = 'Agendamento de Serviço' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is Peças' do
        before { product.name = 'Peças' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end
    end
  end
end
