require_relative 'testing_support/defaults'

Dir["#{File.dirname(__FILE__)}/testing_support/factories/**"].each do |f|
  load File.expand_path(f)
end
