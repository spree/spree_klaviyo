require 'spree_core'
require 'spree_extension'
require 'spree_klaviyo/engine'
require 'spree_klaviyo/version'
require 'spree_klaviyo/configuration'

module SpreeKlaviyo
  mattr_accessor :queue

  def self.queue
    @@queue ||= Spree.queues.default
  end
end
