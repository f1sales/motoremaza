# frozen_string_literal: true

require_relative 'motoremaza/version'
require 'f1sales_custom/parser'
require 'f1sales_custom/source'
require 'f1sales_custom/hooks'
require 'byebug'

module Motoremaza
  class Error < StandardError; end

  class F1SalesCustom::Hooks::Lead
    def self.switch_source(lead)
      @product_name = lead.product.name.downcase
      return nil unless lead.attachments.empty?

      return nil if lead.description.downcase['daitan']

      return nil if unwanted_product

      lead.source.name
    end

    def self.unwanted_product
      return true if @product_name['peças']

      return true if @product_name['agendamento de serviço']
    end
  end
end
