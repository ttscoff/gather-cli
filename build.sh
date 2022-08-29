#!/bin/bash

newversion=$(git semnext $1)
echo "Update: $newversion"
filename="gather-cli-$newversion.pkg"
rm -rf dist
mkdir dist
success=$(/usr/bin/env ruby -rcsv -rfileutils <<EORUBY
	mainfile = 'Sources/gather/gather.swift'
	content = IO.read(mainfile)
	content.sub!(/(?mi)(?<=var VERSION = ")(.*?)(?=")/, "$newversion")
	File.open(mainfile, 'w') { |f| f.puts content }
	print "OK"
EORUBY
)

if [[ $success == "OK" ]]; then
	changelog -u
	/bin/bash package.sh $newversion
# 	/usr/bin/env ruby -rfileutils <<EORUBY
# 		readme = IO.read('README.md').force_encoding('ASCII-8BIT').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
# 		readme.gsub!(/\<!--VER-->(.*?)\<!--END VER-->/, "$newversion")
# 		readme.gsub!(/<!--JEKYLL(.*?)-->/m, '')
# 		readme.gsub!(/<!--GITHUB-->(.*?)<!--END GITHUB-->/m, '\1')
# 		readme.gsub!(/<!--(END )?README-->\n/m, '')
# 		File.open('dist/README.md', 'w') { |f| f.puts readme }
# EORUBY
# 	cp CHANGELOG.md LICENSE.md dist/

	# zip $filename dist/* &> /dev/null
	# codesign --force --verbose --sign 'Developer ID Application: Brett Terpstra' $filename
	# rm -rf gather
	curl -H "X-JFrog-Art-Api:AKCp8nG6L95SWyqZEGycbEviPzjPCvMUaUNbcuMRSxSRGU9oBYo42sRKF3xLwvaCiDZNUfGad" -T $filename  "https://ttscoff.jfrog.io/artifactory/bottles-thelab/$filename"
	if [[ $USER == "ttscoff" ]]; then
		mv "$filename" ~/Sites/dev/bt/source/downloads/
		rm ~/Sites/dev/bt/source/downloads/gather-cli-latest.zip
		ln -s ~/Sites/dev/bt/source/downloads/$filename ~/Sites/dev/bt/source/downloads/gather-cli-latest.zip
	fi

	res=$(/usr/bin/env ruby -rcsv -rfileutils <<EORUBY
	csvfile = File.expand_path("~/Sites/dev/bt/downloads.csv")
	FileUtils.cp(csvfile, csvfile+".bak")
	downloads = CSV.read(csvfile)
	t = Time.now
	updated = t.strftime("%a %b %d %H:%M:%S %z %Y")
	updated_short = t.strftime("%Y-%m-%d")
	f = File.open(csvfile,"wb")
	downloads.map! {|row|
	  if row[0] == "54"
	    answers = {"id" => "54", "version" => "$newversion", "filename" => "$filename"}
	    row[2] = %Q{/downloads/#{answers["filename"]}}
	    row[3] = answers["version"]
	    row[7] = updated
	  end
	  f.puts row.to_csv
	}
	
	puts "OK"
EORUBY
);

	if [[ $res == "OK" ]]; then
		cp .build/apple/Products/Release/gather /usr/local/bin/
		git commit -am "Preparing for $newversion release"
		git push
		hub release create -m "v${newversion}" $newversion
		git pull
	else
		echo "Ruby failure..."
	fi
fi
