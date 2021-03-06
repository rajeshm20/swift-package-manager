/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import libc
import POSIX
import Foundation


/// This file contains temporary shim functions for use during the adoption of
/// AbsolutePath and RelativePath.  The eventual plan is to use the FileSystem
/// API for all of this, at which time this file will go way.  But since it is
/// important to have a quality FileSystem API, we will evolve it slowly.
///
/// Meanwhile this file bridges the gap to let call sites be as clean as pos-
/// sible, while making it fairly easy to find those calls later.

public func isDirectory(_ path: AbsolutePath) -> Bool {
    // Copied from Utilities.Path.
    var mystat = stat()
    let rv = stat(path.asString, &mystat)
    return rv == 0 && (mystat.st_mode & S_IFMT) == S_IFDIR
}

public func isFile(_ path: AbsolutePath) -> Bool {
    // Copied from Utilities.Path.
    var mystat = stat()
    let rv = stat(path.asString, &mystat)
    return rv == 0 && (mystat.st_mode & S_IFMT) == S_IFREG
}

public func isSymlink(_ path: AbsolutePath) -> Bool {
    // Copied from Utilities.Path.
    var mystat = stat()
    let rv = lstat(path.asString, &mystat)
    return rv == 0 && (mystat.st_mode & S_IFMT) == S_IFLNK
}

public func exists(_ path: AbsolutePath) -> Bool {
    // Copied from Utilities.Path.
    return access(path.asString, F_OK) == 0
}

/// Returns the "real path" corresponding to `path` by resolving any symbolic links.
public func resolveSymlinks(_ path: AbsolutePath) -> AbsolutePath {
    let pathStr = path.asString
  #if os(Linux)
    // FIXME: This is really unfortunate but seems to be the only way to invoke this functionality on Linux.
    let url = URL(fileURLWithPath: pathStr)
    guard let resolvedPathStr = (try? url.resolvingSymlinksInPath())?.path else { return path }
  #else
    // FIXME: It's unfortunate to have to cast to NSString here but apparently the String method is deprecated.
    let resolvedPathStr = (pathStr as NSString).resolvingSymlinksInPath
  #endif
    // FIXME: We should measure if it's really more efficient to compare the strings first.
    return (resolvedPathStr == pathStr) ? path : AbsolutePath(resolvedPathStr)
}

/// Creates a new, empty directory at `path`.  If needed, any non-existent ancestor paths are also created.  If there is already a directory at `path`, this function does nothing (in particular, this is not considered to be an error).
public func makeDirectories(_ path: AbsolutePath) throws {
  #if os(Linux)
    try FileManager.default().createDirectory(atPath: path.asString, withIntermediateDirectories: true, attributes: [:])
  #else
    try FileManager.default.createDirectory(atPath: path.asString, withIntermediateDirectories: true, attributes: [:])
  #endif
}

/// Recursively deletes the file system entity at `path`.  If there is no file system entity at `path`, this function does nothing (in particular, this is not considered to be an error).
public func removeFileTree(_ path: AbsolutePath) throws {
  #if os(Linux)
    try FileManager.default().removeItem(atPath: path.asString)
  #else
    try FileManager.default.removeItem(atPath: path.asString)
  #endif
}

/// Creates a symbolic link at `path` whose content points to `dest`.  If `relative` is true, the symlink contents will be a relative path, otherwise it will be absolute.
public func symlink(_ path: AbsolutePath, pointingAt dest: AbsolutePath, relative: Bool = true) throws {
    let destString = relative ? dest.relative(to: path.parentDirectory).asString : dest.asString
    let rv = libc.symlink(destString, path.asString)
    guard rv == 0 else { throw SystemError.symlink(errno, path.asString, dest: destString) }
}

public func rename(_ path: AbsolutePath, to dest: AbsolutePath) throws {
    let rv = libc.rename(path.asString, dest.asString)
    guard rv == 0 else { throw SystemError.rename(errno, old: path.asString, new: dest.asString) }
}

public func unlink(_ path: AbsolutePath) throws {
    let rv = libc.unlink(path.asString)
    guard rv == 0 else { throw SystemError.unlink(errno, path.asString) }
}
