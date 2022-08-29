#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'csv'
filename = ARGV[0]
new_version = ARGV[1]

csvfile = File.expand_path('~/Sites/dev/bt/downloads.csv')
FileUtils.cp(csvfile, "#{csvfile}.bak")
downloads = CSV.read(csvfile)
t = Time.now
updated = t.strftime('%a %b %d %H:%M:%S %z %Y')

f = File.open(csvfile, 'wb')
downloads.map! do |row|
  if row[0] == '54'
    answers = { id: '54', version: new_version, filename: filename }
    row[2] = "/downloads/#{answers[:filename]}"
    row[3] = answers[:version]
    row[7] = updated
  end
  f.puts row.to_csv
end

print 'OK'
