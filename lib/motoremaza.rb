# frozen_string_literal: true

require_relative 'motoremaza/version'
require 'f1sales_custom/parser'
require 'f1sales_custom/source'
require 'f1sales_custom/hooks'

module Motoremaza
  class Error < StandardError; end

  class F1SalesCustom::Hooks::Lead
    def self.switch_source(lead)
      # return nil unless lead.attachments.empty?

      return nil unless lead.description.downcase['remaza']

      lead.source.name
    end
  end
end

kubectl delete pod motoremaza-6cd87cf668-qcmr4
kubectl delete pod sidekiq-motoremaza-7fb768fcf8-8xrtz

