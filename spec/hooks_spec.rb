require 'ostruct'

RSpec.describe F1SalesCustom::Hooks::Lead do
  context 'when come from myHonda' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.attachments = []
      lead.product = product

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
        expect(switch_source).to be_nil
        # expect(switch_source).to eq('Email da Honda')
      end
    end

    context 'Needs to filter cars' do
      context 'when is new city' do
        before { product.name = 'NEW CITY HATCHBACK - Touring - Automático' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is hr-v' do
        before { product.name = 'NEW HR-V - EXL - Automático' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is cr-v' do
        before { product.name = 'NEW CR-V - EXL - Automático' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is wr-v' do
        before { product.name = 'NEW WR-V - EXL - Automático' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is civic' do
        before { product.name = 'Honda Civic' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is fit' do
        before { product.name = 'Honda FIT' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end
    end

    context 'when services come in product name' do
      context 'when is agendamento' do
        before { product.name = 'Agendamento de Serviço' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is manutenção' do
        before { product.name = 'Manutenção Periódica' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end

      context 'when is manutenção' do
        before { product.name = 'Seguro Moto Consumidor' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end
    end
  end
end
