require 'spree_core'
require 'spree_extension'
require 'spree_klaviyo/engine'
require 'spree_klaviyo/version'
require 'spree_klaviyo/configuration'

module SpreeKlaviyo
  def self.queue
    'spree_klaviyo'
  end
end
