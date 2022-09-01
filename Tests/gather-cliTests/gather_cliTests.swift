import class Foundation.Bundle
import XCTest

func gatherWith(args: [String], stdin: String?) -> String? {
    // Some of the APIs that we use below are available in macOS 10.13 and above.
    guard #available(macOS 10.13, *) else {
        return nil
    }

    // Mac Catalyst won't have `Process`, but it is supported for executables.
    #if !targetEnvironment(macCatalyst)
        do {
            let fooBinary = productsDirectory.appendingPathComponent("gather")

            let process = Process()
            process.executableURL = fooBinary

            if stdin != nil {
                let inpipe = Pipe()
                let testString = "<p>Testing gather</p>"
                inpipe.fileHandleForWriting.write(Data(testString.utf8))
                inpipe.fileHandleForWriting.closeFile()
                process.standardInput = inpipe
            }

            let pipe = Pipe()
            process.standardOutput = pipe

            process.arguments = args
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            fatalError("Error running Gather")
        }
    #endif
}

/// Returns path to the built products directory.
var productsDirectory: URL {
    #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
    #else
        return Bundle.main.bundleURL
    #endif
}

final class gather_cliTests: XCTestCase {
    func testTitleOnly() throws {
        let args = ["--title-only", "https://github.com/vimtaai/critic-markup"]
        let output = gatherWith(args: args, stdin: nil)
        XCTAssertNotNil(output)
        XCTAssertEqual(output!, "vimtaai/critic-markup\n")
    }

    func testMetadata() throws {
        let args = ["--metadata", "https://github.com/vimtaai/critic-markup?query=value&something=else#nowhere"]
        let output = gatherWith(args: args, stdin: nil)
        XCTAssertNotNil(output)
        XCTAssertNotNil(output!.range(of: "source: https://github.com/vimtaai/critic-markup\n"))
    }

    func testStdin() throws {
        let args = ["--stdin", "--html", "--no-readability"]
        let testString = "<p>Testing gather</p>"
        let output = gatherWith(args: args, stdin: testString)
        XCTAssertNotNil(output)
        XCTAssertEqual(output, "Testing gather\n")
    }
}
