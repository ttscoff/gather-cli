## 2.0.40

#### FIXED

- Using --inline-links without --no-paragraph links would throw an error, which is just stupid. What was he thinking?
- Documentation refers to `--inline` instead of `--inline-links` (Thanks rand)

## 2.0.34

#### IMPROVED

- Documentation update

#### FIXED

- Double h1 headlines being inserted
- Respect --no-include-title better

## 2.0.33

#### NEW

- Use %date, %slugdate, %title, and %slug in --file paths
- %slug for url scheme templates

#### IMPROVED

- Sanitize filenames where needed

## 2.0.32

#### IMPROVED

- Rely more heavily on title tags instead of trying to parse h1/h2 effectively

## 2.0.31

#### IMPROVED

- Add %filename placeholder to url templates, which inserts a sanitized version of the page title

## 2.0.30

#### NEW

- Generate any url scheme using templates (`--url-template "handler://method?txt=%text&title=%title"`)
- Open generated urls automatically with `--url-open`
- Define a fallback title for various outputs in case one isn't found (usually in HTML snippets) `--fallback-title`

#### IMPROVED

- Better title detection for HTML snippets
- If a title can be detected from an HTML snippet, include it if requested
- If a canonical link can be found for the page, use it as the "source url" in output

#### FIXED

- Crash when HTML snippet is missing head
- URL encode ALL characters to avoid malformed url handlers
- Images wrapped in links missing opening bracket

## 2.0.29

#### CHANGED

- Moved the new --nv-add/url options to --nvu-add/url

#### NEW

- Generate nvALT urls and notes with --nv-url and --nv-add

## 2.0.28

#### NEW

- --nv-url to output results as an nvUltra url handler url
- --nv-add to immediately create a new note in nvUltra
- --nv-notebook to specify a path to the notebook folder you wish to use
- --title-only to output only the title of the page

## 2.0.27

#### NEW

- --[no-]include-title to enable/disable the inclusion of an h1 with the page title
- --[no-]include-source option to enable/disable the source link
- --metadata option to include MultiMarkdown metadata with title, source, and current date

#### IMPROVED

- Sort options in --help

## 2.0.23

#### FIXED

- Missing space around links in text
- Include h1 title, can be disabled with --no-include-title

## 2.0.20

#### FIXED

- Versioning script inserting variable names

## 2.0.19

#### IMPROVED

- Revamping build process to use signed packages

## 2.0.13

#### IMPROVED

- Improved build/deploy automation

## 2.0.10

#### IMPROVED

- Added notes about macOS quarantine to README

## 2.0.9

#### FIXED

- Attempting to codesign the binary to see if I can avoid macOS warnings

## 2.0.8

#### NEW

- Special handling for StackExchange. Formatting is automatically cleaned up, accepted answers moved to the top, and there are options for filtering by minimum upvotes, including or excluding comments, and including only accepted answers

## 2.0.5

#### IMPROVED

- Documentation updates

## 2.0.2

#### NEW

- Initial release of the successor to read2text. A Swift-based version with more options and better parsing

#### IMPROVED

- Documentation updates

## 2.0.0

#### NEW

- Initial commit
