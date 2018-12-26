module Gem
  class LoadError < StandardError
  end

  class Deprecate
    def self.skip
      true
    end
  end
end

def gem(*args)
end

require 'rubygems/version'
