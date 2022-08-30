# gather-cli

<!--README-->
<!--GITHUB-->![Howzit banner image](https://cdn3.brettterpstra.com/uploads/2022/08/gatherheader-rb.webp)<!--END GITHUB-->
<!--JEKYLL{% img aligncenter 800 220 /uploads/2022/08/gatherheader-rb.jpg "Howzit banner image" %}-->

Current version: <!--VER-->2.0.22<!--END VER-->

This project is the successor to read2text, which was a Python based tool that used Arc90 Readability and html2text to convert web URLs to Markdown documents, ready to store in your notes. It takes its name from another of my similar projects that I've since retired. It was this, but with a GUI, and this is infinitely more scriptable and is designed to nestle into your favorite tools and projects.

This version is Swift-based and compiled as a binary that doesn't require Python or any other processor to run. It has more options, better parsing, and should be an all-around useful tool, easy to incorporate into almost any project.

The code is available [on GitHub](https://github.com/ttscoff/gather-cli). It's built as a Swift Package and can be compiled using the `swift` command line tool. I'm just learning Swift, so I guarantee there's a lot of stupidity in the code. If you dig in, feel free to kindly point out my errors.

### Installation

The first options is to compile it yourself.

You can build your own binary by downloading the source code and running the swift compiler:

```
git clone https://github.com/ttscoff/gather-cli
cd gather-cli
swift build -c release
```

The gather binary will be located in `.build/release/gather`. Copy it wherever you keep your binaries in your PATH.

#### Downloading


<!--GITHUB-->
[Download the PKG installer from BrettTerpstra.com](https://brettterpstra.com/downloads/gather-cli-latest.pkg)
<!--END GITHUB-->
<!--JEKYLL{% download 54 %}-->

Double click to run the installer. This will install gather to /usr/local/bin with root permissions.

### Usage

```console
USAGE: gather [<options>] [<url>]

ARGUMENTS:
  <url>                   The URL to parse

OPTIONS:
  -v, --version           Display current version number
  -s, --stdin             Get input from STDIN
  -p, --paste             Get input from clipboard
  --env <env>             Get input from and environment variable
  -c, --copy              Copy output to clipboard
  --html                  Expect raw HTML instead of a URL
  --readability/--no-readability
                          Use readability (default: true)
  --paragraph-links/--no-paragraph-links
                          Insert link references after each paragraph (default: true)
  --inline-links/--no-inline-links
                          Use inline links (default: false)
  --unicode/--no-unicode  Use Unicode characters instead of ascii replacements (default: true)
  --accepted-only         Only save accepted answer from StackExchange question pages
  --min-upvotes <min-upvotes>
                          Only save answers from StackExchange page with minimum number of upvotes (default: 0)
  --include-comments      Include comments on StackExchange question pages
  -f, --file <file>       Save output to file path
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

#### Stack Exchange Options

Gather has some features specifically for saving answers from StackExchange sites like StackOverflow and AskDifferent. I love saving answers I find on StackOverflow to my notes for later where I can have them tagged, indexed, searchable, and curated. I wanted to make Gather a perfect tool for quickly making those notes.

You don't have to do anything to trigger Gather's special handling of StackExchange sites. If the page you're trying to save has a body class of "question-page", it will kick in automatically. By default it will save all answers without comments. If there's a selected answer it will be moved to the top of the list.

To save only the accepted answer (if there is one) for a question, use `--accepted-only`.

Comments can often be fruitful (and important) to an answer, but they also get messy on popular posts, so they're ignored by default. To include comments when saving a StackExchange page, just add `--include-comments`.

Lastly, sometimes there's more than one good answer worth saving, but a bunch of zero-vote errors in judgement you don't need in your notes. Use `--min-upvotes X` to filter answers by a minimum number of upvotes. For example, `--min-upvotes 60` would easily weed out the less-desirable answers on an older question. Filtering by upvotes does not affect the accepted answer, if that exists it's included no matter how many upvotes is has (or doesn't have).

<!--END README-->

