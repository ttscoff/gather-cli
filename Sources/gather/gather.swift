import AppKit
import ArgumentParser
import Cocoa
import Foundation
import HTML2Text
import Readability
var VERSION = "2.0.28"

var acceptedAnswerOnly = false
var disableReadability = false
var escapeSpecial = false
var grafLinks = true
var includeAnswerComments = false
var includeMetadata = false
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

func markdownify_input(html: String?, read: Bool?) -> (String?, String) {
    let read = read
    return markdownify_html(html: html, read: read, url: nil)
}

func markdownify_html(html: String?, read: Bool?, url: String?, baseurl: String? = "") -> (String?, String) {
    var html = html
    var title = String?(nil)

    if html != nil {
        if read != false {
            do {
                let readability = Readability(html: html!)
                readability.allSpecialHandling = true
                readability.acceptedAnswerOnly = acceptedAnswerOnly
                readability.includeAnswerComments = includeAnswerComments
                readability.minimumAnswerUpvotes = minimumAnswerUpvotes
                let started = readability.start()

                if started {
                    html = try readability.getContent()!.html()
                    html = html!.trimmingCharacters(in: .whitespacesAndNewlines)
                    title = try readability.getTitle()?.text()
                }

            } catch {
                print("Error parsing readability, trying without")
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

        if includeMetadata {
            let date = iso_datetime()

            if title != nil {
                meta += "title: \"\(title!)\""
            } else {
                meta += "title: Clipped on \(date)"
            }

            if url != nil {
                meta += "\nsource: \(url!)"
            }

            meta += "\ndate: \(date)"
            meta += "\n\n"
        }

        if includeSourceLink, url != nil {
            if title != nil {
                if includeTitleAsH1 {
                    source = "# \(title!)\n\n[Source](\(url!) \"\(title!)\")\n\n"
                } else {
                    source = "[Source](\(url!) \"\(title!)\")\n\n"
                }
            } else {
                source = "[Source](\(url!))\n\n"
            }
        }

        html = "\(meta)\(source)\(html!)"

        return (title, html!)
    }

    return (title, "")
}

func markdownify(url: String?, read: Bool?) -> (String?, String) {
    var url = url
    var html = String?(nil)
    var baseurl = url

    if url == nil, html == nil {
        return (nil, "No valid url, html or text was provided.")
    }

    if url != nil {
        let u = url!.replacingOccurrences(of: "[?&]utm_[^#]+", with: "", options: .regularExpression)
        guard let base = URL(string: u) else {
            exitWithError(error: 1, message: "error: invalid URL")
            return (nil, "")
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
            return (nil, "")
        }

        html = page
        url = u
    }

    return markdownify_html(html: html, read: read, url: url, baseurl: baseurl)
}

func createNvUltraURL(markdown: String?, title: String?, notebook: String?) -> String {
    var note_title = ""

    if title == nil {
        note_title = "\(iso_datetime()) Clipped Note"
    } else {
        note_title = title!
    }

    var components = URLComponents()
    components.scheme = "x-nvultra"
    components.host = "make"
    components.path = "/"

    components.queryItems = [
        URLQueryItem(name: "txt", value: markdown),
        URLQueryItem(name: "title", value: note_title),
        URLQueryItem(name: "notebook", value: notebook),
    ]

    return components.string ?? ""
}

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

func writeToFile(filename: String, content: String) {
    do {
        try content.write(to: URL(fileURLWithPath: filename), atomically: true, encoding: String.Encoding.utf8)
        print("Saved to file: \(filename)")
    } catch let error as NSError {
        print("Failed writing to file: \(filename), Error: " + error.localizedDescription)
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

    @Option(name: .shortAndLong, help: "Save output to file path", completion: .file())
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

    @Flag(help: "Output as an nvUltra URL")
    var nvUrl = false

    @Flag(help: "Add output to nvUltra immediately")
    var nvAdd = false

    @Option(help: "Specify an nvUltra notebook for the 'make' URL")
    var nvNotebook: String = ""

    @Flag(name: .shortAndLong, help: "Display current version number")
    var version = false

    @Argument(help: "The URL to parse")
    var url: String = ""

    mutating func run() throws {
        var input: String?

        if inlineLinks {
            if paragraphLinks {
                throw ValidationError("error: --inline cannot be used with --paragraph-links")
            }
            inline = inlineLinks
        } else if paragraphLinks {
            if inline {
                throw ValidationError("error: --inline cannot be used with --paragraph-links")
            }

            grafLinks = paragraphLinks
        }

        unicodeSnob = unicode
        includeAnswerComments = includeComments
        acceptedAnswerOnly = acceptedOnly
        minimumAnswerUpvotes = minUpvotes
        includeTitleAsH1 = includeTitle
        onlyOutputTitle = titleOnly
        includeMetadata = metadata
        includeSourceLink = includeSource
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

        if input != nil {
            (title, markdown) = markdownify_input(html: input, read: readability)
            // if onlyOutputTitle {
            //     if let title = get_title(html: input, url: nil) {
            //         output = title.trimmingCharacters(in: .whitespacesAndNewlines)
            //     }
            // } else {
            //     output = markdownify_input(html: input, read: readability).trimmingCharacters(in: .whitespacesAndNewlines)
            // }
        } else if url != "" {
            (title, markdown) = markdownify(url: url, read: readability)
            // if onlyOutputTitle {
            //     if let title = get_title(html: nil, url: url) {
            //         output = title.trimmingCharacters(in: .whitespacesAndNewlines)
            //     }
            // } else {
            //     output = markdownify(url: url, read: readability).trimmingCharacters(in: .whitespacesAndNewlines)
            // }
        } else {
            throw CleanExit.helpRequest()
        }

        if onlyOutputTitle {
            output = title!.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            output = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if output != nil {
            if nvUrl || nvAdd {
                output = createNvUltraURL(markdown: markdown, title: title, notebook: nvNotebook)

                if nvAdd {
                    let url = URL(string: output!)!
                    if NSWorkspace.shared.open(url) {
                        throw CleanExit.message("Added to nvUltra")
                    }
                    throw ValidationError("Error adding to nvUltra")
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
                writeToFile(filename: file, content: output!)
            } else {
                print(output!)
            }
        } else {
            throw ValidationError("Empty output")
        }
    }
}
