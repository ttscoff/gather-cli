#!/usr/bin/env ruby -rcsv -rfileutils

mainfile = ARGV[0]
content = IO.read(mainfile)
content.sub!(/(?mi)(?<=var VERSION = ")(.*?)(?=")/, "$newversion")
File.open(mainfile, 'w') { |f| f.puts content }

src = 'src/README.md'
dest = 'README.md'

readme = IO.read(src).force_encoding('ASCII-8BIT').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')

content = readme.match(/(?<=\<!--README-->)(.*?)(?=\<!--END README-->)/m)[0]
content = "# Gather CLI\n\n#{content}"
content.gsub!(/\<!--VER-->(.*?)\<!--END VER-->/, "$newversion")
content.gsub!(/<!--GITHUB-->(.*?)<!--END GITHUB-->/m, '\1')
content.gsub!(/<!--JEKYLL(.*?)-->/m, '')

File.open(dest, 'w') { |f| f.puts(content) }

print "OK"
