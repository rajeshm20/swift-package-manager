/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Basic
import PackageModel

import enum Utility.ColorWrap
import enum Utility.Stream
import func POSIX.exit
import func Utility.isTTY
import var Utility.stderr

public enum Error: Swift.Error {
    case noManifestFound
    case invalidToolchain
    case buildYAMLNotFound(String)
    case repositoryHasChanges(String)
}

extension Error: FixableError {
    public var error: String {
        switch self {
        case .noManifestFound:
            return "no \(Manifest.filename) file found"
        case .invalidToolchain:
            return "invalid inferred toolchain"
        case .buildYAMLNotFound(let value):
            return "no build YAML found: \(value)"
        case .repositoryHasChanges(let value):
            return "repository has changes: \(value)"
        }
    }

    public var fix: String? {
        switch self {
        case .noManifestFound:
            return "create a file named \(Manifest.filename) or run `swift package init` to initialize a new package"
        case .repositoryHasChanges(_):
            return "stage the changes and reapply them after updating the repository"
        default:
            return nil
        }
    }
}

@noreturn public func handle(error: Any, usage: ((String) -> Void) -> Void) {

    switch error {
    case OptionParserError.multipleModesSpecified(let modes):
        print(error: error)

        if isTTY(.stdErr) && (modes.contains{ ["--help", "-h"].contains($0) }) {
            print("", to: &stderr)
            usage { print($0, to: &stderr) }
        }
    case OptionParserError.noCommandProvided(let hint):
        if !hint.isEmpty {
            print(error: error)
        }
        if isTTY(.stdErr) {
            usage { print($0, to: &stderr) }
        }
    case is OptionParserError:
        print(error: error)
        if isTTY(.stdErr) {
            let argv0 = CommandLine.arguments.first ?? "swift package"
            print("enter `\(argv0) --help' for usage information", to: &stderr)
        }
    case let error as FixableError:
        print(error: error.error)
        if let fix = error.fix {
            print(fix: fix)
        }
    default:
        print(error: error)
    }

    exit(1)
}

private func print(error: Any) {
    if ColorWrap.isAllowed(for: .stdErr) {
        print(ColorWrap.wrap("error:", with: .Red, for: .stdErr), error, to: &stderr)
    } else {
        let cmd = CommandLine.arguments.first?.basename ?? "SwiftPM"
        print("\(cmd): error:", error, to: &stderr)
    }
}

private func print(fix: String) {
    if ColorWrap.isAllowed(for: .stdErr) {
        print(ColorWrap.wrap("fix:", with: .Yellow, for: .stdErr), fix, to: &stderr)
    } else {
        print("fix:", fix, to: &stderr)
    }
}
