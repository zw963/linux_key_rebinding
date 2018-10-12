# frozen_string_literal: true

require 'jaro_winkler/version'

if RUBY_ENGINE == 'ruby'
  require "jaro_winkler/jaro_winkler_ext.2.5.0.so"
else
  require 'jaro_winkler/jaro_winkler_pure'
end
