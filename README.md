# Gather CLI


![Howzit banner image](https://cdn3.brettterpstra.com/uploads/2022/08/gatherheader-rb.webp)


Current version: 2.0.39

This project is the successor to read2text, which was a Python based tool that used Arc90 Readability and html2text to convert web URLs to Markdown documents, ready to store in your notes. It takes its name from another of my similar projects that I've since retired. It was this, but with a GUI, and this is infinitely more scriptable and is designed to nestle into your favorite tools and projects.

This version is Swift-based and compiled as a binary that doesn't require Python or any other processor to run. It has more options, better parsing, and should be an all-around useful tool, easy to incorporate into almost any project.

The code is available [on GitHub](https://github.com/ttscoff/gather-cli). It's built as a Swift Package and can be compiled using the `swift` command line tool. I'm just learning Swift, so I guarantee there's a lot of stupidity in the code. If you dig in, feel free to kindly point out my errors.

### Installation

#### Via Homebrew

The easiest way to install Gather is with [Homebrew](https://brew.sh). Homebrew requires installing Xcode, so if you'd rather not deal with the hassle, see the download option below. If you use a lot of command line utilities or want a package manager for all your non-MAS apps, I highly recommend getting Homebrew [set up](https://brew.sh).

If you have Homebrew installed, just run:

```console
brew tap ttscoff/thelab
brew install gather-cli
```

If you get errors, the most common solution is to run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. Seems to fix just about every issue I've had reported.

#### Manual Install

You can build your own binary by downloading the source code and running the swift compiler:

```console
git clone https://github.com/ttscoff/gather-cli
cd gather-cli
swift build -c release
```

The gather binary will be located in `.build/release/gather`. Copy it wherever you keep your binaries in your PATH.

#### Downloading



[Download the PKG installer from BrettTerpstra.com](https://brettterpstra.com/downloads/gather-cli-latest.pkg)



Double click to run the installer. This will install gather to /usr/local/bin with root permissions.

### Usage

```
USAGE: gather [<options>] [<url>]

ARGUMENTS:
  <url>                   The URL to parse

OPTIONS:
  -c, --copy              Copy output to clipboard
  --env <env>             Get input from and environment variable
  -f, --file <file>       Save output to file path. Accepts %date, %slugdate, %title, and %slug
  --html                  Expect raw HTML instead of a URL
  --include-source/--no-include-source
                          Include source link to original URL (default: true)
  --include-title/--no-include-title
                          Include page title as h1 (default: true)
  --inline-links          Use inline links
  --metadata              Include page title, date, source url as MultiMarkdown metadata
  -p, --paste             Get input from clipboard
  --paragraph-links/--no-paragraph-links
                          Insert link references after each paragraph (default: true)
  --readability/--no-readability
                          Use readability (default: true)
  -s, --stdin             Get input from STDIN
  -t, --title-only        Output only page title
  --unicode/--no-unicode  Use Unicode characters instead of ascii replacements (default: true)
  --accepted-only         Only save accepted answer from StackExchange question pages
  --include-comments      Include comments on StackExchange question pages
  --min-upvotes <min-upvotes>
                          Only save answers from StackExchange page with minimum number of upvotes (default: 0)
  --nv-url                Output as an Notational Velocity/nvALT URL
  --nv-add                Add output to Notational Velocity/nvALT immediately
  --nvu-url               Output as an nvUltra URL
  --nvu-add               Add output to nvUltra immediately
  --nvu-notebook <nvu-notebook>
                          Specify an nvUltra notebook for the 'make' URL
  --url-template <url-template>
                          Create a URL scheme from a template using %title, %text, %notebook, %source, %date, %filename, and %slug
  --fallback-title <fallback-title>
                          Fallback title to use if no title is found, accepts %date
  --url-open              Open URL created from template
  -v, --version           Display current version number
  -h, --help              Show help information.
```

In its simplest form, Gather expects a URL. Just `gather https://brettterpstra.com` to perform a readability extraction of the main content and a conversion to Markdown, output to STDOUT.

#### Input Options

In addition to passing a URL as an argument, you can use `--stdin` to pass the URL via a pipe, e.g. `echo https://brettterpstra.com | gather --stdin`.

You can have the URL pulled from your clipboard automatically with `--paste`. Just copy the URL from your browser and run `gather -p`. This is ideal for use in macOS Services or Shortcuts.

You can also pass raw HTML to Gather and have it perform its magic on the source code. Just add `--html` to the command and it will parse it directly rather than trying to extract a URL. Depending on what's in your clipboard, Readability parsing can cause errors. If you run into trouble, run it without Readability using `--no-readability`. HTML can be passed via `--stdin` or `--paste`, e.g. `cat myfile.html | gather --html --stdin`.

If you specify the `--html` and `--paste` flags, Gather will first check your HTML pasteboard for content. This means that if you've copied by selecting text on a web page or any web view, Gather can operate on that "rich text" version. If you've copied plain text source, that pasteboard will be empty and Gather will fall back to using the plain text pasteboard.

You can also pull a URL or HTML from an environment variable using `--env VARIABLE`. This is mainly for incorporation into things like PopClip, which passes HTML via the $POPCLIP_HTML variable.

#### Output Options

By default the formatted Markdown is output to STDOUT (your terminal screen), where it can be piped to a file or a clipboard utility. There are some built-in options for those things as well.

If you add `--copy` the command, the output will be placed on the system clipboard.

If you add `--file PATH` to the command, the results will be saved to the path you specify. Any existing files at that path will be overwritten. If you want to append output, you're better off using shell redirection, e.g. `gather myurl.com >> compilation.md`

#### Formatting Options

You can control the formatting of the output in a couple of ways.

By default Gather will use reference-style links, and will place the references directly after the paragraph where they occur. You can switch to inline links using `--inline`, and you can suppress the per-paragraph linking and collect them all at the end of the document using `--no-paragraph-links`.

By default Gather will maintain Unicode characters in the output. If you'd prefer to have an ASCII equivalent substituted, you can use `--no-unicode`. This feature may not be working properly yet.

`--include-source` will add a `[Source](PAGE_URL)` link to the top of the document. You can disable this link with `--no-include-source`.

`--include-title` will attempt to insert an H1 title if the output doesn't have one. If a title can be determined and a matching h1 doesn't exist, it will be added at the top of the document. This is handy when the page has its header (and headline) outside of the content area that Readability chooses as the main block, and the option defaults to true. `--no-include-title` will disable this, but it will not remove an existing h1 from the document.

If you just want to get the title of a URL, use `--title-only` to output a plain text title with no decoration.

#### Stack Exchange Options

Gather has some features specifically for saving answers from StackExchange sites like StackOverflow and AskDifferent. I love saving answers I find on StackOverflow to my notes for later where I can have them tagged, indexed, searchable, and curated. I wanted to make Gather a perfect tool for quickly making those notes.

You don't have to do anything to trigger Gather's special handling of StackExchange sites. If the page you're trying to save has a body class of "question-page", it will kick in automatically. By default it will save all answers without comments. If there's a selected answer it will be moved to the top of the list.

To save only the accepted answer (if there is one) for a question, use `--accepted-only`.

Comments can often be fruitful (and important) to an answer, but they also get messy on popular posts, so they're ignored by default. To include comments when saving a StackExchange page, just add `--include-comments`.

Lastly, sometimes there's more than one good answer worth saving, but a bunch of zero-vote errors in judgement you don't need in your notes. Use `--min-upvotes X` to filter answers by a minimum number of upvotes. For example, `--min-upvotes 60` would easily weed out the less-desirable answers on an older question. Filtering by upvotes does not affect the accepted answer, if that exists it's included no matter how many upvotes is has (or doesn't have).

#### nvUltra/nvALT Options

If you're running nvUltra, you can output clipped web pages directly to a notebook.

`--nvu-url` will generate a x-nvultra://make url that, when opened, will add the markdown version of the web page as a note, titled with the page title. This flag simply outputs the url (or copies it with `--copy`) and can be used as part of another script that handles the link.

`--nvu-add` will immediately open the url and add your note to nvUltra.

You can include a `--nvu-notebook PATH` option to specify which notebook the note gets added to. If this is left out, the note will be added to the frontmost open notebook in nvUltra.

[Here's a Shortcut](https://github.com/ttscoff/gather-cli/raw/main/extras/Gather%20to%20nvUltra.shortcut) that accepts text or URLs and runs `gather --nv-add` on them. I trigger it with LaunchBar to send the current page from my browser straight to nvUltra.

The `url` and `add` options work with just `--nv` instead of `--nvu` to generate an `nv://` url that will work with Notational Velocity or nvALT.

#### Other URL handlers

You can generate any kind of url scheme you want using `--url-template`. This is a string that can contain the following placeholders (all URL encoded):

- %title: The title of the page
- %text: The markdown text of the page
- %notebook: The contents of the `--nvu-notebook` option, can be used for additional meta in another key
- %source: The canonical URL of the captured page, if available
- %date: Today's date and time in the format YYYY-mm-dd HH:MM
- %filename: The title of the page sanitized for use as a file name
- %slug: The title of the page lowercased, all punctuation and spaces replaced with dashes (`using-gather-as-a-web-clipper`)

You can include a fallback title using `--fallback-title "TITLE"`. If a page title can't be determined (common when running on snippets of HTML), this variable will be inserted. You can include the "%date" placeholder, which will be replaced with an ISO datetime.

To show nvUltra's url scheme in this manner:

    --url-template "x-nvultra://make/?txt=%text&title=%filename&notebook=%notebook"

Add the `--url-open` flag to have the URL automatically executed instead of being returned.

