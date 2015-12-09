# coding: utf-8
require 'sunflower'
require 'parallel'

s = Sunflower.new 'commons.wikipedia.org'

# data = JSON.parse File.binread 'log_other.json'
# data += JSON.parse File.binread 'log_crosswiki.json'
titles = JSON.parse File.binread 'log_other_titles.json'
titles += JSON.parse File.binread 'log_crosswiki_titles.json'

data2 = []
# data.map{|a| a['title']}.each_slice(50).each do |slice|
# titles.each_slice(50).each do |slice|
Parallel.each(titles.each_slice(50).to_a, in_threads: 10) do |slice|
	begin
		resp = s.API action: 'query', titles: slice.join('|')
	rescue
		puts $!
		puts $!.backtrace
		retry
	end
	data2 += resp['query']['pages'].values.map{|a| [a['title'], !a['missing']] }
	puts data2.length
end

File.binwrite 'exist.json', JSON.pretty_generate(data2)
