# coding: utf-8
require 'json'

class String
	def strip_heredoc
		indent = scan(/^[ \t]*(?=\S)/).min.length rescue 0
		gsub(/^[ \t]{#{indent}}/, '')
	end
	
	def limit_length len
		if length < len
			self
		else
			self[0, len] + '…'
		end
	end
end

log = JSON.parse File.binread('log.json'), symbolize_names: true

exist = Hash[ JSON.parse File.binread 'exist.json' ]
firstcontrib = JSON.parse File.binread('firstcontrib.json'), symbolize_names: true
contribs = JSON.parse File.binread('contribs.json'), symbolize_names: true

log = log.sort_by{|a| a[:timestamp] }

seenusers = {}
seenusers[''] = true
log.each{|upload|
	user = (upload[ :user ]||'').to_sym
	if seenusers[ user ]
		user_is_new = false 
	else
		first = firstcontrib[ user ]
		user_is_new = !first || upload[:timestamp] <= first[:timestamp]
		seenusers[ user ] = true
	end
	upload[:user_is_new] = user_is_new
	upload[:user_editcount] = contribs[ user ]
}

section_template = <<EOF.strip
== %s ==
{| class="wikitable sortable"
! #
! Thumbnail
! Filename
! Uploader
! <abbr title="This is the very first contribution this user made to Commons">First-time?</abbr>
! <abbr title="Number of non-deleted contributions this user made to Commons">Edit count</abbr>
! Source wiki
! <abbr title="Version of the A/B tested interface the user saw">Bucket</abbr>
|-
%s
|}
EOF

interesting_tags = %w[cross-wiki-upload-1 cross-wiki-upload-2 cross-wiki-upload-3 cross-wiki-upload-4]

page_content = log
	.select{|upload| (upload[:tags] & interesting_tags).length > 0 }
	.group_by{|upload| upload[:timestamp][/^\d{4}-\d{2}-\d{2}/] }
	.map do |timestamp, logs|
		table = logs.map.with_index{|upload, i|
			<<-EOF.strip_heredoc.strip
			| #{i}
			| #{ exist[ upload[:title] ] ? "[[#{upload[:title]}|100x100px]]" : '(deleted)' }
			| [[:#{upload[:title]}|#{upload[:title].sub(/^File:/, '').limit_length 50}]]
			| #{ upload[:user] ? "[[Special:Contributions/#{upload[:user]}|#{upload[:user]}]]" : '(revdeleted)' }
			| #{ upload[:user_is_new] ? 'Yes' : 'No' }
			| #{ upload[:user_editcount] }
			| #{ upload[:comment][ /^Cross-wiki upload from (.+)$/, 1 ] }
			| #{ (upload[:tags] & interesting_tags).first[/\d+/] }
			EOF
		}
		section_template % [timestamp, table.join("\n|-\n")]
	end

out = <<EOF
Cross-wiki uploads that were part of the
[[mw:Multimedia/December 2015 cross-wiki upload A/B test|December 2015 cross-wiki upload A/B test]].

#{page_content.join "\n\n"}
EOF

puts out
