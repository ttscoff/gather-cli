desc "Development version check"
task :ver do
  gver = `git ver`
  cver = IO.read(File.join(File.dirname(__FILE__), "CHANGELOG.md")).match(/^#+ (\d+\.\d+\.\d+(\w+)?)/)[1]
  res = `grep VERSION lib/na/version.rb`
  version = res.match(/VERSION *= *['"](\d+\.\d+\.\d+(\w+)?)/)[1]
  puts "git tag: #{gver}"
  puts "version.rb: #{version}"
  puts "changelog: #{cver}"
end

desc "Changelog version check"
task :cver do
  puts IO.read(File.join(File.dirname(__FILE__), "CHANGELOG.md")).match(/^#+ (\d+\.\d+\.\d+(\w+)?)/)[1]
end
