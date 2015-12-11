# coding: utf-8
require 'sunflower'
require 'parallel'

s = Sunflower.new 'commons.wikipedia.org'

log = JSON.parse File.binread('log.json'), symbolize_names: true

exist = Hash[ JSON.parse File.binread 'exist.json' ]

badcrosswiki = log
	.select{|u| u[:tags].include? 'cross-wiki-upload' }
	.select{|u| !exist[ u[:title] ] }
	.map{|u| u[:title] }

log = exist = nil; GC.start

puts badcrosswiki.length

deletionlog = {}
Parallel.each(badcrosswiki, in_threads: 10) do |title|
	begin
		resp = s.API({
			action: 'query',
			list: 'logevents',
			leprop: 'comment',
			letype: 'delete',
			leaction: 'delete/delete',
			letitle: title,
		})
	rescue
		puts $!
		puts $!.backtrace
		retry
	end
	
	begin
		deletionlog[title] = resp['query']['logevents'][0]['comment'];
	rescue
		puts title
	end
	
	puts deletionlog.length if deletionlog.length % 1000 == 0
end

File.binwrite 'deletionlog.json', JSON.pretty_generate(deletionlog)
