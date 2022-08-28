import AppKit
import ArgumentParser
import Foundation
import HTML2Text
import Readability
var VERSION = "2.0.4"

var disableReadability = false
var inline = false
var grafLinks = true
var unicodeSnob = true
var escapeSpecial = false
var wrapWidth = 0

func exitWithError(error: Int32, message: String? = nil) {
    if message != nil {
        print(message!)
    }
    exit(error)
}

func markdownify_input(html: String?, read: Bool?) -> String {
    let read = read
    return markdownify_html(html: html, read: read, url: nil)
}

func markdownify_html(html: String?, read: Bool?, url: String?, baseurl: String? = "") -> String {
    var html = html
    var title = String?(nil)

    if html != nil {
        if read != false {
            do {
                let readability = Readability(html: html!)
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

        if url != nil {
            if title != nil {
                source = "[Source](\(url!) \"\(title!)\")\n\n"
            } else {
                source = "[Source](\(url!))\n\n"
            }
        }

        html = "\(source)\(html!)"

        return html!
    }

    return ""
}

func markdownify(url: String?, read: Bool?) -> String {
    var url = url
    var html = String?(nil)
    var baseurl = url

    if url == nil, html == nil {
        return "No valid url, html or text was provided."
    }

    if url != nil {
        let u = url!.replacingOccurrences(of: "[?&]utm_[^#]+", with: "", options: .regularExpression)
        guard let base = URL(string: u) else {
            exitWithError(error: 1, message: "error: invalid URL")
            return ""
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
            return ""
        }

        html = page
        url = u
    }

    return markdownify_html(html: html, read: read, url: url, baseurl: baseurl)
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
    @Flag(name: .shortAndLong, help: "Display current version number")
    var version = false

    @Flag(name: .shortAndLong, help: "Get input from STDIN")
    var stdin = false

    @Flag(name: .shortAndLong, help: "Get input from clipboard")
    var paste = false

    @Option(help: "Get input from and environment variable")
    var env: String = ""

    @Flag(name: .shortAndLong, help: "Copy output to clipboard")
    var copy = false

    @Flag(help: "Expect raw HTML instead of a URL")
    var html = false

    @Flag(inversion: .prefixedNo, help: "Use readability")
    var readability = true

    @Flag(inversion: .prefixedNo, help: "Insert link references after each paragraph")
    var paragraphLinks = true

    @Flag(inversion: .prefixedNo, help: "Use inline links")
    var inlineLinks = false

    // @Flag(help: "Escape special characters")
    // var escape = false

    @Flag(inversion: .prefixedNo, help: "Use Unicode characters instead of ascii replacements")
    var unicode = true

    // @Option(name: .shortAndLong, help: "Wrap width (0 for no wrap)")
    // var wrap: Int = 0

    @Option(name: .shortAndLong, help: "Save output to file path", completion: .file())
    var file: String = ""

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

        var output: String? = ""

        if input != nil {
            output = markdownify_input(html: input, read: readability).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if url != "" {
            output = markdownify(url: url, read: readability).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw CleanExit.helpRequest()
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
    }
}
