const std = @import("std");
const Platform = @import("Platform.zig");

pub const standard = &[_][]const u8{
    "x86_64-linux-gnu",
    "aarch64-linux-gnu",
    "x86_64-macos",
    "aarch64-macos",
    "x86_64-windows-gnu",
    "aarch64-windows-gnu",
};

pub fn resolve(b: *std.Build, target_str: []const u8) std.Build.ResolvedTarget {
    const query = std.Target.Query.parse(.{ .arch_os_abi = target_str }) catch |err| {
        std.debug.print("Failed to parse target '{s}': {s}\n", .{ target_str, @errorName(err) });
        @panic("Invalid target string");
    };
    return b.resolveTargetQuery(query);
}

/// Per-target context passed to CI build callbacks
pub const TargetContext = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    target_str: []const u8,
    platform: Platform,
    ci_step: *std.Build.Step,
    install_path: []const u8,
};

/// Standard CI matrix loop: resolves each target, creates platform info,
/// and calls the build function for each. Sets up version file output.
pub fn addCiMatrix(
    b: *std.Build,
    ci_step: *std.Build.Step,
    targets: []const []const u8,
    version: []const u8,
    build_fn: *const fn (TargetContext) void,
) void {
    // Write version file
    const write_version = b.addWriteFiles();
    _ = write_version.add("version", version);
    ci_step.dependOn(&b.addInstallFile(write_version.getDirectory().path(b, "version"), "version").step);

    const install_path = b.getInstallPath(.prefix, ".");

    for (targets) |target_str| {
        const target = resolve(b, target_str);
        const platform = Platform.detect(target.result);

        build_fn(.{
            .b = b,
            .target = target,
            .target_str = target_str,
            .platform = platform,
            .ci_step = ci_step,
            .install_path = install_path,
        });
    }
}

/// Helper to check if a target string matches a given OS name
pub fn isTargetOs(target_str: []const u8, os_name: []const u8) bool {
    return std.mem.indexOf(u8, target_str, os_name) != null;
}

test "CI targets" {
    try std.testing.expectEqual(@as(usize, 6), standard.len);
}

test "isTargetOs" {
    try std.testing.expect(isTargetOs("x86_64-linux-gnu", "linux"));
    try std.testing.expect(isTargetOs("aarch64-macos", "macos"));
    try std.testing.expect(!isTargetOs("x86_64-linux-gnu", "windows"));
}
