#!/usr/bin/env ruby

last_tag = `git describe --tags --abbrev=0`.strip
last_hash = `git rev-parse #{last_tag}`.strip

formula = '/Users/ttscoff/Desktop/Code/homebrew-thelab/Formula/gather-cli.rb'
content = IO.read(formula)
content.sub!(/tag: ".*?", revision: ".*?"/, %(tag: "#{last_tag}", revision: "#{last_hash}"))
File.open(formula, 'w') { |f| f.puts content }

Dir.chdir(File.dirname(formula))
`git commit -a -m "Formula update #{last_tag}"`
`git pull`
`git push`

puts "Formula updated"
