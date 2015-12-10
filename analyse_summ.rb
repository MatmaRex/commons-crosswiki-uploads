# coding: utf-8
require 'json'

log = JSON.parse File.binread('log.json'), symbolize_names: true

comm = log
	.sort_by{|a| a[:timestamp] }
	.map{|a| a[:comment].gsub(/\s+/, ' ') }

puts comm.sort
