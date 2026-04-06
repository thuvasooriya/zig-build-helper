const std = @import("std");
const builtin = @import("builtin");

pub const Platform = @import("Platform.zig");
pub const Simd = @import("Simd.zig");
pub const Flags = @import("Flags.zig");
pub const Config = @import("Config.zig");
pub const Ci = @import("Ci.zig");
pub const Archive = @import("Archive.zig");
pub const Dependencies = @import("Dependencies.zig");
pub const Codegen = @import("Codegen.zig");
pub const Sources = @import("Sources.zig");

pub fn checkZigVersion(comptime minimum_version: []const u8) void {
    const required = std.SemanticVersion.parse(minimum_version) catch unreachable;
    const current = builtin.zig_version;
    if (current.order(required) == .lt) {
        @compileError(std.fmt.comptimePrint(
            "Zig >= {s} required, found {}.{}.{}",
            .{ minimum_version, current.major, current.minor, current.patch },
        ));
    }
}

test {
    _ = Platform;
    _ = Simd;
    _ = Flags;
    _ = Config;
    _ = Ci;
    _ = Archive;
    _ = Dependencies;
    _ = Codegen;
    _ = Sources;
}
