import AppKit
import ArgumentParser
import Cocoa
import Foundation
import HTML2Text
import Readability
var VERSION = "2.0.44"

var acceptedAnswerOnly = false
var disableReadability = false
var escapeSpecial = false
var grafLinks = true
var includeAnswerComments = false
var includeMetadata = false
var includeMetadataYAML = false
var titleFallback = ""
var includeSourceLink = true
var includeTitleAsH1 = true
var onlyOutputTitle = false
var inline = false
var minimumAnswerUpvotes = 0
var unicodeSnob = true
var wrapWidth = 0

func exitWithError(error: Int32, message: String? = nil) {
    if message != nil {
        print(message!)
    }
    exit(error)
}

func get_title(html: String?, url: String?) -> String? {
    var title = String?(nil)

    if html != nil {
        do {
            let readability = Readability(html: html!)
            let started = readability.start()

            if started {
                title = try readability.getTitle()?.text()
            }

        } catch {
            print("Error parsing page")
            return title
        }
    } else if url != nil {
        let u = url!.replacingOccurrences(of: "[?&]utm_[^#]+", with: "", options: .regularExpression)
        guard let page = try? String(contentsOf: URL(string: u)!, encoding: .utf8) else {
            return title
        }

        title = get_title(html: page, url: nil)
    }

    return title
}

func iso_datetime() -> String {
    let dateFormatterPrint = DateFormatter()
    dateFormatterPrint.dateFormat = "yyyy-MM-dd HH:mm"
    return dateFormatterPrint.string(from: Date())
}

func markdownify_input(html: String?, read: Bool?) -> (String?, String, String?) {
    let read = read
    return markdownify_html(html: html, read: read, url: nil)
}

func countH1s(_ s: String, title: String?) -> Int {
    var pattern = "^# ."
    if title != nil {
        pattern = "^# \(NSRegularExpression.escapedPattern(for: title!))"
    }

    let re = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .caseInsensitive])
    let checkRange = NSRange(s.startIndex ..< s.endIndex, in: s)
    return re.matches(in: s, options: [], range: checkRange).count
}

func markdownify_html(html: String?, read: Bool?, url: String?, baseurl: String? = "") -> (String?, String, String?) {
    var html = html
    var title = String?(nil)
    var sourceUrl = url

    if html != nil {
        do {
            let readability = Readability(html: html!)
            readability.allSpecialHandling = true
            readability.acceptedAnswerOnly = acceptedAnswerOnly
            readability.includeAnswerComments = includeAnswerComments
            readability.minimumAnswerUpvotes = minimumAnswerUpvotes
            let started = readability.start()

            if started {
                sourceUrl = readability.canonical
                if sourceUrl == nil {
                    sourceUrl = url
                }
                title = try readability.getTitle()?.text()

                if read != false {
                    html = try readability.getContent()!.html()
                    html = html!.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

        } catch {
            print("Error parsing readability, trying without")
            if read != false {
                return markdownify_html(html: html, read: false, url: url, baseurl: baseurl)
            }
        }

        let h = HTML2Text(baseurl: baseurl!)
        h.links_each_paragraph = grafLinks
        h.inline_links = inline
        h.unicode_snob = unicodeSnob
        h.escape_snob = escapeSpecial
        h.body_width = wrapWidth

        let data = html!

        let html2textresult = h.main(baseurl: baseurl ?? "", data: data)

        html = html2textresult.replacingOccurrences(of: #"([*-+] .*?)\n+(?=[*-+] )"#, with: "$1\n", options: .regularExpression)

        html = html!.replacingOccurrences(of: #"(?m)\n{2,}"#, with: "\n\n")

        html = html!.replacingOccurrences(of: "__BR__", with: "  ")

        var source = ""
        var meta = ""

        if includeMetadata || includeMetadataYAML {
            if includeMetadataYAML {
                meta += "---\n"
            }
            let date = iso_datetime()

            if title != nil {
                meta += "title: \"\(title!)\""
            } else {
                if titleFallback.isEmpty {
                    meta += "title: Clipped on \(date)"
                } else {
                    meta += "title: \(titleFallback.replacingOccurrences(of: #"%date"#, with: date, options: [.regularExpression, .caseInsensitive]))"
                }
            }

            if sourceUrl != nil {
                meta += "\nsource: \(sourceUrl!)"
            }

            meta += "\ndate: \(date)"
            if includeMetadataYAML {
                meta += "\n---\n"
            } else {
                meta += "\n\n"
            }
        }

        if includeSourceLink, sourceUrl != nil {
            if title != nil {
                if includeTitleAsH1 {
                    source = "# \(title!)\n\n[Source](\(sourceUrl!) \"\(title!)\")\n\n"
                } else {
                    source = "[Source](\(sourceUrl!) \"\(title!)\")\n\n"
                }
            } else {
                source = "[Source](\(sourceUrl!))\n\n"
            }
        } else if title != nil, includeTitleAsH1 {
            source = "# \(title!)\n\n"
        }
        html = "\(meta)\(source)\(html!)"

        return (title, html!, sourceUrl)
    }

    return (title, "", url)
}

func markdownify(url: String?, read: Bool?) -> (String?, String, String?) {
    var url = url
    var html = String?(nil)
    var baseurl = url

    if url == nil, html == nil {
        return (nil, "No valid url, html or text was provided.", nil)
    }

    if url != nil {
        let u = url!.replacingOccurrences(of: "[?&]utm_[^#]+", with: "", options: .regularExpression)
        guard let base = URL(string: u) else {
            exitWithError(error: 1, message: "error: invalid URL")
            return (nil, "", nil)
        }

        let scheme = base.scheme
        var host = base.host
        if base.port != nil {
            host = "\(host!):\(base.port!)"
        }

        if scheme != nil, host != nil {
            baseurl = "\(scheme!)://\(host!)"
        }

        guard let page = try? String(contentsOf: URL(string: u)!, encoding: .utf8) else {
            return (nil, "", nil)
        }

        html = page
        url = u
    }

    return markdownify_html(html: html, read: read, url: url, baseurl: baseurl)
}

func urlEncodeQuery(string: String) -> String {
    // Percent encode all characters, even query-safe ones.
    // Query-safe characters were still occasionally creating unparseable urls.
    return NSString(string: string).addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: ""))!
}

func sanitizeFile(name: String, replacement: String?) -> String {
    return name.replacingOccurrences(of: #"[/?<>\\:*|\"\[\]]"#, with: replacement ?? "", options: .regularExpression)
}

func slugifyFile(name: String) -> String {
    var slug = name.trimmingCharacters(in: .whitespacesAndNewlines)
    slug = slug.replacingOccurrences(of: #"[^a-z0-9]"#, with: "-", options: [.regularExpression, .caseInsensitive])
    slug = slug.replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
    return slug.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).lowercased()
}

func createUrlScheme(template: String, markdown: String, title: String?, notebook: String?, source: String?) -> String {
    var note_title = ""
    if title != nil {
        note_title = title!
    }
    var url = template.replacingOccurrences(of: #"%title"#, with: urlEncodeQuery(string: note_title), options: [.regularExpression, .caseInsensitive])
    url = url.replacingOccurrences(of: #"%text"#, with: urlEncodeQuery(string: markdown), options: [.regularExpression, .caseInsensitive])
    url = url.replacingOccurrences(of: #"%notebook"#, with: urlEncodeQuery(string: notebook ?? ""), options: [.regularExpression, .caseInsensitive])
    url = url.replacingOccurrences(of: #"%source"#, with: urlEncodeQuery(string: source ?? ""), options: [.regularExpression, .caseInsensitive])
    url = url.replacingOccurrences(of: #"%date"#, with: urlEncodeQuery(string: iso_datetime()), options: [.regularExpression, .caseInsensitive])
    url = url.replacingOccurrences(of: #"%filename"#, with: urlEncodeQuery(string: sanitizeFile(name: note_title, replacement: " ")), options: [.regularExpression, .caseInsensitive])
    url = url.replacingOccurrences(of: #"%slug"#, with: urlEncodeQuery(string: slugifyFile(name: note_title)), options: [.regularExpression, .caseInsensitive])
    return url
}

// func createNvUltraURL(markdown: String?, title: String?, notebook: String?) -> String {
//     var note_title = ""

//     if title != nil {
//         note_title = title!
//     }

//     var components = URLComponents()
//     components.scheme = "x-nvultra"
//     components.host = "make"
//     components.path = "/"

//     components.queryItems = [
//         URLQueryItem(name: "txt", value: markdown),
//         URLQueryItem(name: "title", value: note_title),
//         URLQueryItem(name: "notebook", value: notebook),
//     ]

//     return components.string ?? ""
// }

func readFromClipboard(html: Bool = false) -> String? {
    let pasteboard = NSPasteboard.general
    var output: String?
    if html {
        output = pasteboard.string(forType: .html)
        if output == nil {
            output = pasteboard.string(forType: .string)
        } else {
            disableReadability = true
        }
    } else {
        output = pasteboard.string(forType: .string)
    }

    return output
}

func writeToClipboard(string: String) {
    if string.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(string, forType: .string)
    }
    print("Content in clipboard")
}

func writeToFile(filename: String, content: String, title: String?) {
    var newname = filename.replacingOccurrences(of: #"%date"#, with: iso_datetime(), options: [.regularExpression, .caseInsensitive])
    newname = newname.replacingOccurrences(of: #"%slugdate"#, with: slugifyFile(name: iso_datetime()), options: [.regularExpression, .caseInsensitive])
    if title != nil {
        newname = newname.replacingOccurrences(of: #"%title"#, with: sanitizeFile(name: title!, replacement: "-"), options: [.regularExpression, .caseInsensitive])
        newname = newname.replacingOccurrences(of: #"%slug"#, with: slugifyFile(name: title!), options: [.regularExpression, .caseInsensitive])
    }
    do {
        try content.write(to: URL(fileURLWithPath: newname), atomically: true, encoding: String.Encoding.utf8)
        print("Saved to file: \(newname)")
    } catch let error as NSError {
        print("Failed writing to file: \(newname), Error: " + error.localizedDescription)
    }
}

func readInput() -> String? {
    var input: String?

    while let line = readLine() {
        if input == nil {
            input = line
        } else {
            input! += "\n" + line
        }
    }

    return input
}

func readEnv(variable: String) -> String? {
    if let input = ProcessInfo.processInfo.environment[variable] {
        return input
    }

    return ""
}

@main
struct Gather: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Copy output to clipboard")
    var copy = false

    @Option(help: "Get input from and environment variable")
    var env: String = ""

    // @Flag(help: "Escape special characters")
    // var escape = false

    @Option(name: .shortAndLong, help: "Save output to file path. Accepts %date, %slugdate, %title, and %slug", completion: .file())
    var file: String = ""

    @Flag(help: "Expect raw HTML instead of a URL")
    var html = false

    @Flag(inversion: .prefixedNo, help: "Include source link to original URL")
    var includeSource = true

    @Flag(inversion: .prefixedNo, help: "Include page title as h1")
    var includeTitle = true

    @Flag(help: "Use inline links")
    var inlineLinks = false

    @Flag(help: "Include page title, date, source url as MultiMarkdown metadata")
    var metadata = false

    @Flag(help: "Include page title, date, source url as YAML front matter")
    var metadataYaml = false

    @Flag(name: .shortAndLong, help: "Get input from clipboard")
    var paste = false

    @Flag(inversion: .prefixedNo, help: "Insert link references after each paragraph")
    var paragraphLinks = true

    @Flag(inversion: .prefixedNo, help: "Use readability")
    var readability = true

    @Flag(name: .shortAndLong, help: "Get input from STDIN")
    var stdin = false

    @Flag(name: .shortAndLong, help: "Output only page title")
    var titleOnly = false

    @Flag(inversion: .prefixedNo, help: "Use Unicode characters instead of ascii replacements")
    var unicode = true

    @Flag(help: "Only save accepted answer from StackExchange question pages")
    var acceptedOnly = false

    @Flag(help: "Include comments on StackExchange question pages")
    var includeComments = false

    @Option(help: "Only save answers from StackExchange page with minimum number of upvotes")
    var minUpvotes: Int = 0

    // @Option(name: .shortAndLong, help: "Wrap width (0 for no wrap)")
    // var wrap: Int = 0

    @Flag(help: "Output as an Notational Velocity/nvALT URL")
    var nvUrl = false

    @Flag(help: "Add output to Notational Velocity/nvALT immediately")
    var nvAdd = false

    @Flag(help: "Output as an nvUltra URL")
    var nvuUrl = false

    @Flag(help: "Add output to nvUltra immediately")
    var nvuAdd = false

    @Option(help: "Specify an nvUltra notebook for the 'make' URL")
    var nvuNotebook: String = ""

    @Option(help: "Create a URL scheme from a template using %title, %text, %notebook, %source, %date, %filename, and %slug")
    var urlTemplate: String = ""

    @Option(help: "Fallback title to use if no title is found, accepts %date")
    var fallbackTitle: String = ""

    @Flag(help: "Open URL created from template")
    var urlOpen = false

    @Flag(name: .shortAndLong, help: "Display current version number")
    var version = false

    @Argument(help: "The URL to parse")
    var url: String = ""

    mutating func run() throws {
        var input: String?

        if inlineLinks {
            grafLinks = false
            inline = inlineLinks
        } else if paragraphLinks {
            inline = false
            grafLinks = paragraphLinks
        }

        unicodeSnob = unicode
        includeAnswerComments = includeComments
        acceptedAnswerOnly = acceptedOnly
        minimumAnswerUpvotes = minUpvotes
        includeTitleAsH1 = includeTitle
        onlyOutputTitle = titleOnly
        includeMetadata = metadata
        includeMetadataYAML = metadataYaml
        includeSourceLink = includeSource
        titleFallback = fallbackTitle
        // escapeSpecial = escape
        // wrapWidth = wrap

        if version {
            throw CleanExit.message("gather-cli v\(VERSION)")
        }

        if html {
            if url != "" {
                throw ValidationError("error: --html cannot be used with a URL argument")
            }
        }

        if stdin || env != "" {
            if env != "" {
                if stdin {
                    throw ValidationError("error: --stdin cannot be used with --env")
                }

                if html {
                    input = readEnv(variable: env)!
                } else {
                    url = readEnv(variable: env)!
                }
            } else {
                if html {
                    input = readInput()!
                } else {
                    url = readInput()!
                }
            }
        }

        if paste {
            if url != "" {
                throw ValidationError("error: --paste cannot be used with a URL argument")
            }

            if html {
                input = readFromClipboard(html: html)!
                if disableReadability {
                    readability = false
                }
            } else {
                url = readFromClipboard()!
            }
        }

        var output: String?
        var title: String?
        var markdown: String
        var sourceUrl: String?

        if input != nil {
            (title, markdown, sourceUrl) = markdownify_input(html: input, read: readability)
        } else if url != "" {
            (title, markdown, sourceUrl) = markdownify(url: url, read: readability)
        } else {
            throw CleanExit.helpRequest()
        }

        if title == nil || title!.isEmpty {
            if titleFallback.isEmpty {
                title = "Clipped Page \(iso_datetime())"
            } else {
                title = titleFallback.replacingOccurrences(of: #"%date"#, with: urlEncodeQuery(string: iso_datetime()), options: [.regularExpression, .caseInsensitive])
            }
        }

        if onlyOutputTitle {
            output = title!.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            output = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if output != nil {
            if nvuUrl || nvuAdd {
                output = createUrlScheme(template: "x-nvultra://make/?txt=%text&title=%filename&notebook=%notebook", markdown: markdown, title: title, notebook: nvuNotebook, source: sourceUrl)

                if nvuAdd || urlOpen {
                    let url = URL(string: output!)

                    if url == nil {
                        throw CleanExit.message("Error parsing generated URL")
                    } else {
                        if NSWorkspace.shared.open(url!) {
                            throw CleanExit.message("Added to nvUltra")
                        }
                        throw CleanExit.message("Error adding to nvUltra")
                    }
                }
            } else if nvUrl || nvAdd {
                output = createUrlScheme(template: "nv://make/?txt=%text&title=%title", markdown: markdown, title: title, notebook: nvuNotebook, source: sourceUrl)

                if nvAdd || urlOpen {
                    let url = URL(string: output!)!
                    if NSWorkspace.shared.open(url) {
                        throw CleanExit.message("Added to NV/nvALT")
                    }
                    throw CleanExit.message("Error adding to NV/nvALT")
                }
            } else if !urlTemplate.isEmpty {
                output = createUrlScheme(template: urlTemplate, markdown: markdown, title: title, notebook: nvuNotebook, source: sourceUrl)

                if urlOpen {
                    let url = URL(string: output!)!
                    if NSWorkspace.shared.open(url) {
                        throw CleanExit.message("Opened URL")
                    }
                    throw CleanExit.message("Error opening URL")
                }
            }

            if copy {
                if file != "" {
                    throw ValidationError("error: --copy cannot be used with --file")
                }
                writeToClipboard(string: output!)
            } else if file != "" {
                if copy {
                    throw ValidationError("error: --copy cannot be used with --file")
                }
                writeToFile(filename: file, content: output!, title: title)
            } else {
                print(output!)
            }
        } else {
            throw ValidationError("Empty output")
        }
    }
}
