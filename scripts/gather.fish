function _gather_env
	env|sed -E 's/([^=]+)=.*$/\1/'
end

complete -c gather -l copy -s c -f -d 'Copy output to clipboard'
complete -c gather -l env -f -r -d 'Get input from and environment variable' -a '(_gather_env)'
complete -c gather -s f -l file -r -F -d 'Save output to file path. Accepts %date, %slugdate, %title, and %slug'
complete -c gather -l html -f -d 'Expect raw HTML instead of a URL'
complete -c gather -l include-source -f -d 'Include source link to original URL'
complete -c gather -l no-include-source -f -d "Don't include source link to original URL"
complete -c gather -l include-title -f -d "Include page title as h1 (default: true)"
complete -c gather -l no-include-title -f -d "Don't include page title as h1"
complete -c gather -l inline-links -f -d "Use inline links"
complete -c gather -l metadata -f -d "Include page title, date, source url as MultiMarkdown metadata"
complete -c gather -l metadata-yaml -f -d "Include page title, date, source url as YAML front matter"
complete -c gather -l paste -s p -f -d "Get input from clipboard"
complete -c gather -l paragraph-links -f -d "Insert link references after each paragraph"
complete -c gather -l no-paragraph-links -f -d "Don't insert link references after each paragraph"
complete -c gather -l readability -f -d "Use readability"
complete -c gather -l no-readability -f -d "Don't use readability"
complete -c gather -l stdin -s s -f -d "Get input from STDIN"
complete -c gather -l title-only -s t -f -d "Output only page title"
complete -c gather -l unicode -f -d "Use Unicode characters instead of ascii replacements"
complete -c gather -l no-unicode -f -d "Don't use Unicode characters instead of ascii replacements"
complete -c gather -l accepted-only -f -d  "Only save accepted answer from StackExchange question pages"
complete -c gather -l include-comments -f -d "Include comments on StackExchange question pages"
complete -c gather -l min-upvotes -r -f -d "Only save answers from StackExchange page with minimum number of upvotes"
complete -c gather -l nv-url -f -d "Output as an Notational Velocity/nvALT URL"
complete -c gather -l nv-add -f -d "Add output to Notational Velocity/nvALT immediately"
complete -c gather -l nvu-url -f -d "Output as an nvUltra URL"
complete -c gather -l nvu-add -f -d "Add output to nvUltra immediately"
complete -c gather -l nvu-notebook -r -F -d "Specify an nvUltra notebook for the 'make' URL"
complete -c gather -l url-template -r -f -d "Create a URL scheme from a template using %title, %text, %notebook, %source, %date, %filename, and %slug"
complete -c gather -l fallback-title -r -f -d "Fallback title to use if no title is found, accepts %date"
complete -c gather -l url-open -f -d "Open URL created from template"
complete -c gather -l version -s v -f -d "Display current version number"
complete -c gather -l help -s h -f -d "Show help information"
