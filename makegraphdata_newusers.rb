# coding: utf-8
require 'json'

log = JSON.parse File.binread('log.json'), symbolize_names: true

exist = Hash[ JSON.parse File.binread 'exist.json' ]
firstcontrib = JSON.parse File.binread('firstcontrib.json'), symbolize_names: true

log = log.sort_by{|a| a[:timestamp] }

seenusers = {}
seenusers[''] = true
log.select!{|upload|
	user = (upload[ :user ]||'').to_sym
	if seenusers[ user ]
		out = false 
	else
		first = firstcontrib[ user ]
		out = !first || upload[:timestamp] <= first[:timestamp]
		seenusers[ user ] = true
	end
	out
}

def classify upload
	comment = upload[:comment]
	tags = upload[:tags]
	return :crosswikiupload if tags.include? 'cross-wiki-upload'
	return :uploadwizard if comment == 'User created page with UploadWizard'
	return :gwtoolset if comment.start_with? '[[Commons:GWT|GWToolset]]'
	return :vicuna if comment.start_with? 'VicuñaUploader'
	return :norwegian if comment.start_with? 'From the Norwegian National Library'
	return :flickr2commons if comment.end_with? '[[Commons:Flickr2Commons|Flickr2Commons]]'
	return :androidapp if comment == 'Uploaded using Android Commons app'
	return :iosapp if comment == 'Uploaded with Commons for iOS'
	return :lrmediawiki if comment.start_with? 'Uploaded with LrMediaWiki'
	return :transferred if comment.start_with? 'Bot Move: Original uploader'
	return :transferred if comment =~ /^Transferred from [\w-]+\.wikipedia/
	return :transferred if comment == 'file was transfered from Ukrainian Wikipedia'
	return :geograph2commons if comment =~ /geograph2commons/
	return :croptool if comment =~ /CropTool/
	return :oldupload if comment.start_with? '== {{int:filedesc}} =='
	return :oldupload if comment.start_with? '=={{int:filedesc}}=='
	return :other
end

types = [
	:crosswikiupload,
	:uploadwizard,
	:gwtoolset,
	:vicuna,
	:norwegian,
	:flickr2commons,
	:androidapp,
	:iosapp,
	:lrmediawiki,
	:transferred,
	:geograph2commons,
	:croptool,
	:oldupload,
	:other,
]

out = [ 'timestamp' ]
out += types.map{|t| ["#{t}-good", "#{t}-bad"] }.flatten
puts out.join("\t")

log
	.group_by{|a| a[:timestamp][/^\d{4}-\d{2}-\d{2}/] }
	.each do |timestamp, logs|
		data = {}
		logs.each do |upload|
			type = classify upload
			data[type] ||= []
			data[type] << upload[:title]
		end
		
		out = [timestamp]
		types.each do |type|
			data[type] ||= []
			good = data[type].count{|a| exist[ a ] }
			out << good << data[type].length-good
		end
		
		puts out.join("\t")
	end
