# frozen_string_literal: true

require_relative 'motoremaza/version'
require 'f1sales_custom/parser'
require 'f1sales_custom/source'
require 'f1sales_custom/hooks'

module Motoremaza
  class Error < StandardError; end

  class F1SalesCustom::Hooks::Lead
    class << self
      def switch_source(lead)
        @lead = lead
        return nil unless lead.attachments.empty?

        return nil if unwanted_description

        return nil if unwanted_product

        lead.source.name
      end

      private

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
