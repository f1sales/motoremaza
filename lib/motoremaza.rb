# frozen_string_literal: true

require_relative 'motoremaza/version'
require 'f1sales_custom/parser'
require 'f1sales_custom/source'
require 'f1sales_custom/hooks'

module Motoremaza
  class Error < StandardError; end

  class F1SalesCustom::Hooks::Lead
    def self.switch_source(lead)
      product_name = lead.product.name.downcase
      return nil unless lead.attachments.empty?

      return nil if product_name['hr-v']

      return nil if product_name['wr-v']

      return nil if product_name['cr-v']

      return nil if product_name['city']

      return nil if product_name['civic']

      return nil if product_name['fit']

      return nil if product_name['agendamento']

      return nil if product_name['manutenção']

      return nil if product_name['seguro moto']

      lead.source.name
    end
  end
end
