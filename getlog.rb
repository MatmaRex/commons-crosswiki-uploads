# coding: utf-8
require 'sunflower'

s = Sunflower.new 'commons.wikipedia.org'

q = 'action=query&leend=2015-10-01T00:00:00Z&list=logevents&lelimit=max&leprop=title|user|timestamp|comment|tags&letype=upload&leaction=upload%2Fupload&continue='
data = []
continue = ''

while true
	resp = s.API(q + continue)
	data += resp['query']['logevents']
	p data.last['timestamp']
	break if !resp['continue']
	continue = resp['continue']['continue'] + '&lecontinue=' + resp['continue']['lecontinue']
end

require 'json'
File.binwrite 'log.json', JSON.generate(data)
