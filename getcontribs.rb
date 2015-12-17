# coding: utf-8
require 'sunflower'
require 'parallel'

s = Sunflower.new 'commons.wikipedia.org'

log = JSON.parse File.binread('log.json'), symbolize_names: true

users = log
	.map{|u| u[:user] }
	.uniq.compact.sort

log = nil; GC.start

puts users.length

contribs = {}
Parallel.each(users.each_slice(50).to_a, in_threads: 10) do |slice|
	begin
		resp = s.API({
			action: 'query',
			list: 'users',
			usprop: 'editcount',
			ususers: slice.join('|'),
		})
	rescue
		puts $!
		puts $!.backtrace
		retry
	end
	
	contribs.merge! Hash[ resp['query']['users'].map{|u| [ u['name'], u['editcount'] ] } ]
	
	puts contribs.length if contribs.length % 1000 == 0
end

File.binwrite 'contribs.json', JSON.pretty_generate(contribs)
