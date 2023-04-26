require 'ostruct'
require 'faker'
require 'webmock/rspec'
require 'byebug'

RSpec.describe F1SalesCustom::Hooks::Lead do
  context 'when come from myHonda' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.attachments = []
      lead.product = product
      lead.customer = customer
      lead.description = 'REMAZA CENTRO'
      lead.id = Faker::Crypto.md5

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'myHonda'
      source
    end

    let(:customer) do
      customer = OpenStruct.new
      customer.name = Faker::Name.name
      customer.email = Faker::Internet.email
      customer.phone = Faker::PhoneNumber.phone_number

      customer
    end

    let(:product) do
      product = OpenStruct.new
      product.name = ''

      product
    end

    let(:switch_source) { described_class.switch_source(lead) }

    context 'when a dealer name is detected' do
      let(:dealers_list_json) do
        {
          'Empresas' => [
            {
              'RAZSOC' => 'PRIMARCA - SAO CAETANO',
              'CNPJ' => '63078489000134'
            },
            {
              'RAZSOC' => 'PRIMARCA - SAO MIGUEL',
              'CNPJ' => '63078489001025'
            },
            {
              'RAZSOC' => 'DAITAN - IBIRAPUERA',
              'CNPJ' => '67375899000289'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - IBIRAPUERA',
              'CNPJ' => '54267463000143'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - CENTRO',
              'CNPJ' => '54267463003401'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - SANTANA',
              'CNPJ' => '54267463001387'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - SAO BERNARDO',
              'CNPJ' => '54267463001549'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - TATUAPE',
              'CNPJ' => '54267463001620'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - BUTANTA',
              'CNPJ' => '54267463001891'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - TABOAO',
              'CNPJ' => '54267463002006'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - CARRAO',
              'CNPJ' => '54267463002197'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - IPIRANGA',
              'CNPJ' => '54267463002510'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - DIADEMA',
              'CNPJ' => '54267463003088'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - ASSUNCAO',
              'CNPJ' => '54267463003169'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - RUDGE RAMOS',
              'CNPJ' => '54267463003240'
            },
            {
              'RAZSOC' => 'MOTO REMAZA - PACAEMBU',
              'CNPJ' => '54267463003320'
            }
          ]
        }.to_json
      end

      let(:crm_gold_url) { Faker::Internet.url }
      let(:dealers_list_url) { Faker::Internet.url }
      let(:crm_gold_id) { Faker::Crypto.md5 }
      let(:crm_event_code) { Faker::Number.number(digits: 5) }

      before do
        allow(ENV)
          .to receive(:fetch)
          .with('CRM_GOLD_URL')
          .and_return(crm_gold_url)
        allow(ENV)
          .to receive(:fetch)
          .with('CRM_GOLD_ID')
          .and_return(crm_gold_id)
        allow(ENV)
          .to receive(:fetch)
          .with('DEALERS_LIST_URL')
          .and_return(dealers_list_url)
      end

      let(:dealers_list_request) do
        stub_request(
          :get,
          dealers_list_url
        ).to_return(status: 200, body: dealers_list_json, headers: {})
      end

      context 'when post to CRM Gold is not sucessful' do
        let(:lead_json) do
          {
            'idLead' => lead.id,
            'idCRM' => crm_gold_id,
            'Nome' => customer.name,
            'Email' => customer.email,
            'Telefone' => customer.phone,
            'Observacao' => product.name,
            'CNPJ_Unidade' => '54267463003401',
            'TipoInteresse' => 'Novos',
            'Origem' => 'myHonda'
          }.to_json
        end

        let(:failed_crm_gold) do
          { 'erro' => true }.to_json
        end

        let(:crm_gold_request) do
          stub_request(
            :post,
            crm_gold_url
          ).with(
            body: lead_json
          ).to_return(status: 200, body: failed_crm_gold, headers: {})
        end

        before do
          crm_gold_request
          dealers_list_request
          lead.description = 'Concessionária: REMAZA CENTRO - Código: 1034952 - Tipo: HDA - Motocicletas'
          switch_source
        end

        it 'append [NAO INSERIDO CRM GOLD]' do
          expect(lead.description).to eq('Concessionária: REMAZA CENTRO - Código: 1034952 - Tipo: HDA - Motocicletas [NAO INSERIDO CRM GOLD]')
        end
      end

      context 'when post to CRM Gold is sucessful' do
        let(:crm_gold_request) do
          stub_request(
            :post,
            crm_gold_url
          ).with(
            body: lead_json
          ).to_return(status: 200, body: { 'erro' => false, 'codEvento' => crm_event_code }.to_json, headers: {})
        end

        context 'when dealership is SBC' do
          before do
            crm_gold_request
            dealers_list_request
            lead.description = 'Concessionária: REMAZA SBC; Código: 1054953; Tipo: CNH - Consórcio Hond'
            switch_source
          end

          let(:lead_json) do
            {
              'idLead' => lead.id,
              'idCRM' => crm_gold_id,
              'Nome' => customer.name,
              'Email' => customer.email,
              'Telefone' => customer.phone,
              'Observacao' => product.name,
              'CNPJ_Unidade' => '54267463001549',
              'TipoInteresse' => 'Novos',
              'Origem' => 'myHonda'
            }.to_json
          end

          it 'insert lead on CRM Gold as SAO BERNADO DO CAMPO' do
            expect(crm_gold_request).to have_been_made
          end
        end

        context 'when dealership is found' do
          before do
            crm_gold_request
            dealers_list_request
            lead.description = 'Concessionária: REMAZA CENTRO; Código: 1634313; Tipo: HDA - Motocicletas'
            switch_source
          end

          let(:lead_json) do
            {
              'idLead' => lead.id,
              'idCRM' => crm_gold_id,
              'Nome' => customer.name,
              'Email' => customer.email,
              'Telefone' => customer.phone,
              'Observacao' => product.name,
              'CNPJ_Unidade' => '54267463003401',
              'TipoInteresse' => 'Novos',
              'Origem' => 'myHonda'
            }.to_json
          end

          it 'insert lead on CRM Gold' do
            expect(crm_gold_request).to have_been_made
          end

          it 'append [INSERIDO CRM GOLD]' do
            expect(lead.description).to eq("Concessionária: REMAZA CENTRO; Código: 1634313; Tipo: HDA - Motocicletas [INSERIDO CRM GOLD EVENTO: #{crm_event_code}]")
          end
        end
      end
    end

    context 'when it comes by robot' do
      before do
        lead.description = ''
      end

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

    context 'when dealership is DAITAN' do
      before { lead.description = 'Concessionária: DAITAN - Código: 1015699' }

      it 'return nil source' do
        expect(switch_source).to be_nil
      end
    end

    context 'when descritption contain type Serviços' do
      before { lead.description = 'Concessionária: REMAZA - Código: 1015699 - Tipo: CS - Serviços e Peças' }

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

      context 'when is Peças' do
        before { product.name = 'Manutenção Periódica' }

        it 'return nil source' do
          expect(switch_source).to be_nil
        end
      end
    end
  end

  context 'when lead is from Webmotors' do
    let(:lead) do
      lead = OpenStruct.new
      lead.source = source
      lead.attachments = []
      lead.product = product
      lead.customer = customer
      lead.description = 'Valor: 10800 Ano: 2019'
      lead.id = Faker::Crypto.md5

      lead
    end

    let(:source) do
      source = OpenStruct.new
      source.name = 'Webmotors - TATUAPE'
      source.integration = integration

      source
    end

    let(:integration) do
      integration = OpenStruct.new
      integration.name = 'TATUAPE'
      integration.reference = '1234567890001'

      integration
    end

    let(:customer) do
      customer = OpenStruct.new
      customer.name = Faker::Name.name
      customer.email = Faker::Internet.email
      customer.phone = Faker::PhoneNumber.phone_number

      customer
    end

    let(:product) do
      product = OpenStruct.new
      product.name = 'Yamaha Neo 125 BWV9J66'

      product
    end

    let(:switch_source) { described_class.switch_source(lead) }

    context 'when post to CRM Gold is sucessful' do
      let(:crm_gold_url) { Faker::Internet.url }
      let(:crm_gold_id) { Faker::Crypto.md5 }
      let(:crm_event_code) { Faker::Number.number(digits: 5) }

      let(:crm_gold_request) do
        stub_request(
          :post,
          crm_gold_url
        ).with(
          body: lead_json
        ).to_return(status: 200, body: { 'erro' => false, 'codEvento' => crm_event_code }.to_json, headers: {})
      end

      let(:lead_json) do
        {
          'idLead' => lead.id,
          'idCRM' => crm_gold_id,
          'Nome' => customer.name,
          'Email' => customer.email,
          'Telefone' => customer.phone,
          'Observacao' => product.name,
          'CNPJ_Unidade' => '1234567890001',
          'TipoInteresse' => 'Novos',
          'Origem' => 'Webmotors - TATUAPE'
        }.to_json
      end

      before do
        allow(ENV)
          .to receive(:fetch)
          .with('CRM_GOLD_URL')
          .and_return(crm_gold_url)
        allow(ENV)
          .to receive(:fetch)
          .with('CRM_GOLD_ID')
          .and_return(crm_gold_id)
      end

      before do
        crm_gold_request
        switch_source
      end

      it 'insert lead on CRM Gold' do
        expect(crm_gold_request).to have_been_made
      end

      it 'append [INSERIDO CRM GOLD]' do
        expect(lead.description).to eq("Valor: 10800 Ano: 2019 [INSERIDO CRM GOLD EVENTO: #{crm_event_code}]")
      end
    end
  end
end
