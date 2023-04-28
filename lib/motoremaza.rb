# frozen_string_literal: true

require_relative 'motoremaza/version'
require 'f1sales_custom/parser'
require 'f1sales_custom/source'
require 'f1sales_custom/hooks'

module Motoremaza
  class Error < StandardError; end

  class F1SalesCustom::Hooks::Lead
    class << self
      INSERTED_CRM_GOLD = '[INSERIDO CRM GOLD EVENTO: event_code]'
      NOT_INSERTED_CRM_GOLD = '[NAO INSERIDO CRM GOLD]'

      def switch_source(lead)
        @lead = lead
        return nil unless lead.attachments.empty?

        return nil if unwanted_description

        return nil if unwanted_product

        post_crm_gold
        post_lead_webmotors if source_name_down['webmotors']

        source_name
      end

      private

      def source_name
        lead_source.name
      end

      def source_name_down
        source_name.downcase
      end

      def lead_source
        @lead.source
      end

      def integration_reference
        lead_source.integration.reference
      end

      def post_crm_gold
        @lead.description = "#{@lead.description} #{NOT_INSERTED_CRM_GOLD}"
        lead_description = @lead.description

        dealer_name = lead_description.match(/Concessionária: (.*?);/)
        return unless dealer_name

        dealer = parse_dealer(dealer_name)
        post_lead(dealer)
      end

      def parse_dealer(dealer_name)
        dealer_name = dealer_name[1].gsub('REMAZA', '').strip
        dealer_name = 'SAO BERNARDO' if dealer_name == 'SBC'
        dealers_list = HTTP.get(ENV.fetch('DEALERS_LIST_URL')).body

        JSON.parse(dealers_list)['Empresas'].detect do |dealer|
          name_description = dealer['RAZSOC'].scan(/MOTO REMAZA - (.*)/).flatten.first
          dealer_name == name_description
        end
      end

      def post_lead(dealer)
        customer = @lead.customer
        lead_payload = crm_gold_payload(customer, dealer)
        response = HTTP.post(
          ENV.fetch('CRM_GOLD_URL'),
          json: lead_payload
        )

        handle_response(response)
      end

      def crm_gold_payload(customer, dealer)
        {
          'idLead' => @lead.id.to_s,
          'idCRM' => ENV.fetch('CRM_GOLD_ID'),
          'Nome' => customer.name,
          'Email' => customer.email,
          'Telefone' => customer.phone,
          'Observacao' => @lead.product.name,
          'CNPJ_Unidade' => dealer['CNPJ'],
          'TipoInteresse' => 'Novos',
          'Origem' => source_name_gold
        }
      end

      def handle_response(response)
        response_body = JSON.parse(response.body)
        return unless response.code == 200 && response_body['erro'] == false

        update_description(response_body['codEvento'].to_s)
      end

      def update_description(crm_event_code)
        crm_inserted_description = INSERTED_CRM_GOLD.gsub('event_code', crm_event_code)
        @lead.description = @lead.description.gsub(NOT_INSERTED_CRM_GOLD, '').strip
        @lead.description = "#{@lead.description} #{crm_inserted_description}"
      end

      def source_name_gold
        return 'WEBMOTORS' if source_name_down['webmotors']
        return 'MERCADO LIVRE' if source_name_down['mercado livre']
        return 'OLX' if source_name_down['olx']
        return 'RD STATION' if source_name_down['rd station']
        return 'myHonda' if source_name_down['honda']

        source_name
      end

      def post_lead_webmotors
        dealer = {}
        dealer['CNPJ'] = integration_reference
        post_lead(dealer)
      end

      def product_name
        @lead.product.name.downcase || ''
      end

      def description
        @lead.description.downcase || ''
      end

      def unwanted_product
        return true if product_name['peças']

        return true if product_name['agendamento de serviço']

        return true if product_name['manutenção periódica']
      end

      def unwanted_description
        return true if description['daitan']

        return true if description['serviço']
      end
    end
  end
end
