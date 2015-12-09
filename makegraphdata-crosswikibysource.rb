# coding: utf-8
require 'json'

log = JSON.parse File.binread('log_other.json'), symbolize_names: true
log += JSON.parse File.binread('log_crosswiki.json'), symbolize_names: true

exist = JSON.parse File.binread 'exist.json'
exist = Hash[ exist ]

crosswiki = log.select{|u| u[:tags].include? 'cross-wiki-upload' }
sources = crosswiki.map{|u| u[:comment] }.uniq
$stderr.puts "Unique: #{sources.length} wikis"

puts "source\tgood\tbad"

sources.each do |comment|
	wiki = comment.sub( 'Cross-wiki upload from ', '' )

	good, bad = log
		.select{|u| u[:comment] == comment }
		.partition{|u| exist[ u[:title] ] }
	
	next if good.length + bad.length < 10
	
	puts "#{wiki}\t#{good.length}\t#{bad.length}"
end
