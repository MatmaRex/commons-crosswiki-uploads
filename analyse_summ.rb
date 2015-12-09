# coding: utf-8
require 'json'

log = JSON.parse File.binread('log_other.json'), symbolize_names: true
log += JSON.parse File.binread('log_crosswiki.json'), symbolize_names: true

# exist = JSON.parse File.binread 'exist.json'
# exist = Hash[ exist ]

comm = log
	.sort_by{|a| a[:timestamp] }
	.map{|a| a[:comment].gsub(/\s+/, ' ') }

puts comm.sort
