#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'set_process_name_linux'
require 'rbindkeys'

set_process_name_linux('rbindkeys')
Rbindkeys::CLI.main ARGV
