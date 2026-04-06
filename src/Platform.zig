const std = @import("std");

const Platform = @This();

os: std.Target.Os.Tag,
arch: std.Target.Cpu.Arch,
is_windows: bool,
is_darwin: bool,
is_linux: bool,
is_bsd: bool,
is_unix: bool,
is_posix: bool,
is_musl: bool,
is_gnu: bool,
is_mingw: bool,
is_big_endian: bool,
ptr_width: u8,

pub fn detect(target: std.Target) Platform {
    const is_darwin = target.os.tag.isDarwin();
    const is_bsd = switch (target.os.tag) {
        .freebsd, .openbsd, .netbsd, .dragonfly => true,
        else => false,
    };
    const is_windows = target.os.tag == .windows;
    const is_linux = target.os.tag == .linux;
    const is_musl = target.abi == .musl;
    const is_gnu = target.abi == .gnu;
    const is_mingw = is_windows and target.abi == .gnu;

    return .{
        .os = target.os.tag,
        .arch = target.cpu.arch,
        .is_windows = is_windows,
        .is_darwin = is_darwin,
        .is_linux = is_linux,
        .is_bsd = is_bsd,
        .is_unix = is_linux or is_darwin or is_bsd,
        .is_posix = !is_windows,
        .is_musl = is_musl,
        .is_gnu = is_gnu,
        .is_mingw = is_mingw,
        .is_big_endian = target.cpu.arch.endian() == .big,
        .ptr_width = if (target.ptrBitWidth() == 64) 64 else 32,
    };
}

/// Link common POSIX libraries (pthread, math)
pub fn linkPosixLibs(self: Platform, lib: *std.Build.Step.Compile) void {
    if (!self.is_windows) {
        lib.linkSystemLibrary("pthread");
        lib.linkSystemLibrary("m");
    }
}

/// Link Windows system libraries by name
pub fn linkWindowsLibs(self: Platform, lib: *std.Build.Step.Compile, libs: []const []const u8) void {
    if (self.is_windows) {
        for (libs) |name| lib.linkSystemLibrary(name);
    }
}

/// Link macOS frameworks by name
pub fn linkDarwinFrameworks(self: Platform, lib: *std.Build.Step.Compile, frameworks: []const []const u8) void {
    if (self.is_darwin) {
        for (frameworks) |name| lib.linkFramework(name);
    }
}

/// Link common Unix networking libraries
pub fn linkUnixNetLibs(self: Platform, lib: *std.Build.Step.Compile) void {
    if (self.is_windows) {
        lib.linkSystemLibrary("ws2_32");
        lib.linkSystemLibrary("wsock32");
    }
}
