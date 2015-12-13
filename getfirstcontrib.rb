# coding: utf-8
require 'sunflower'
require 'parallel'

s = Sunflower.new 'commons.wikipedia.org'

log = JSON.parse File.binread('log.json'), symbolize_names: true

users = log
	.map{|u| u[:user] }
	.uniq.compact.sort

log = nil; GC.start

firstcontrib = {}

while users.length > 0
	users_deferred = []
	done = 0
	
	Parallel.each(users.each_slice(50).to_a, in_threads: 5) do |slice|
	# users.each_slice(50) do |slice|
		begin
			resp = s.API({
				action: 'query',
				list: 'usercontribs',
				uclimit: 'max',
				ucdir: 'newer',
				ucprop: 'title|timestamp|comment|tags',
				ucuser: slice.join('|'),
			})
		rescue
			puts $!
			puts slice[0]
			# probably a timeout. try a smaller group, defer the rest
			users_deferred.push *(slice[10, 40])
			slice = slice[0, 10]
			retry
		end
		
		add = resp['query']['usercontribs']
			.group_by{|r| r['user'] }
			.map{|user, contribs| [ user, contribs.first ] }
		add = Hash[ add ]
		
		firstcontrib.merge! add
		
		if !resp['continue']
			# got all the users. this happens in particular when all the users have 0 edits...
			done += slice.length
		else
			# don't use continue, but add remaining users back
			# this prevents getting all contribs of users who have more than 500
			users_deferred.push *(slice - add.keys)
			done += add.keys.length
		end
		
		puts "#{done}/#{users.length}, deferred #{users_deferred.length}"
	end
	
	users = users_deferred
end

File.binwrite 'firstcontrib.json', JSON.pretty_generate(firstcontrib)
