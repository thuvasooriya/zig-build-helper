//! Build dependency checking and management
const std = @import("std");

/// Dependency mode for optional dependencies
pub const Mode = enum {
    static, // Use bundled/zig-built dependency
    linked, // Link against system-installed library
    none, // Disable feature entirely
};

/// Link a dependency based on its mode: static artifact, system library, or nothing
pub fn linkStaticOrSystem(
    lib: *std.Build.Step.Compile,
    mode: Mode,
    static_artifact: ?*std.Build.Step.Compile,
    system_name: []const u8,
) void {
    switch (mode) {
        .static => if (static_artifact) |artifact| lib.linkLibrary(artifact),
        .linked => lib.linkSystemLibrary(system_name),
        .none => {},
    }
}

/// Extract version from git URL (e.g., git+https://github.com/org/repo?ref=v1.2.3)
pub fn extractVersionFromUrl(url: []const u8) ?[]const u8 {
    const ref_marker = "?ref=";
    if (std.mem.indexOf(u8, url, ref_marker)) |idx| {
        var version_str = url[idx + ref_marker.len ..];
        if (version_str.len > 0 and version_str[0] == 'v') {
            version_str = version_str[1..];
        }
        if (std.mem.indexOf(u8, version_str, "#")) |hash_idx| {
            version_str = version_str[0..hash_idx];
        }
        return version_str;
    }
    return null;
}

test "Dependency version extraction" {
    const url1 = "git+https://github.com/example/repo?ref=v1.2.3";
    try std.testing.expectEqualStrings("1.2.3", extractVersionFromUrl(url1).?);

    const url2 = "git+https://github.com/example/repo?ref=5.030";
    try std.testing.expectEqualStrings("5.030", extractVersionFromUrl(url2).?);

    const url3 = "https://github.com/example/repo";
    try std.testing.expect(extractVersionFromUrl(url3) == null);

    const url4 = "git+https://github.com/example/repo?ref=v1.6.0#45102247a82396fabac5241c64305b13ed711335";
    try std.testing.expectEqualStrings("1.6.0", extractVersionFromUrl(url4).?);
}
