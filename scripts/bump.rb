#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'

mainfile = ARGV[0]
new_version = ARGV[1]
src = ARGV[2] # 'src/_README.md'
dest = ARGV[3] # 'README.md'

content = IO.read(mainfile)
content.sub!(/(?mi)(?<=var VERSION = ")(.*?)(?=")/, new_version)
File.open(mainfile, 'w') { |f| f.puts content }

readme = IO.read(src).force_encoding('ASCII-8BIT').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

content = readme.match(/(?<=\<!--README-->)(.*?)(?=\<!--END README-->)/m)[0]
content = "# Gather CLI\n\n#{content}"
content.gsub!(/<!--VER-->(.*?)<!--END VER-->/, new_version)
content.gsub!(/<!--GITHUB-->(.*?)<!--END GITHUB-->/m, '\1')
content.gsub!(/<!--JEKYLL(.*?)-->/m, '')

File.open(dest, 'w') { |f| f.puts(content) }

print "OK"
