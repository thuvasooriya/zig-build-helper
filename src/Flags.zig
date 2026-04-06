//! Compiler flag utilities
const std = @import("std");

/// Standard C compiler flags
pub const C = struct {
    pub const warnings = &[_][]const u8{ "-Wall", "-Wextra" };
    pub const warnings_strict = &[_][]const u8{ "-Wall", "-Wextra", "-Werror", "-Wpedantic" };
    pub const c99 = &[_][]const u8{"-std=c99"};
    pub const c11 = &[_][]const u8{"-std=c11"};
    pub const c17 = &[_][]const u8{"-std=c17"};
    pub const gnu_source = &[_][]const u8{"-D_GNU_SOURCE"};
    pub const pic = &[_][]const u8{"-fPIC"};
    pub const pie = &[_][]const u8{"-fPIE"};
};

/// Standard C++ compiler flags
pub const Cxx = struct {
    pub const cpp14 = &[_][]const u8{"-std=c++14"};
    pub const cpp17 = &[_][]const u8{"-std=c++17"};
    pub const cpp20 = &[_][]const u8{"-std=c++20"};
    pub const no_rtti = &[_][]const u8{"-fno-rtti"};
    pub const no_exceptions = &[_][]const u8{"-fno-exceptions"};
};

/// Builder for dynamic flag lists
pub const Builder = struct {
    list: std.ArrayListUnmanaged([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Builder {
        return .{
            .list = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Builder) void {
        self.list.deinit(self.allocator);
    }

    pub fn appendSlice(self: *Builder, flags: []const []const u8) void {
        self.list.appendSlice(self.allocator, flags) catch @panic("OOM");
    }

    pub fn append(self: *Builder, flag: []const u8) void {
        self.list.append(self.allocator, flag) catch @panic("OOM");
    }

    pub fn appendIf(self: *Builder, condition: bool, flag: []const u8) void {
        if (condition) self.append(flag);
    }

    pub fn items(self: *const Builder) []const []const u8 {
        return self.list.items;
    }
};

test "Flags builder" {
    const allocator = std.testing.allocator;
    var b = Builder.init(allocator);
    defer b.deinit();

    b.appendSlice(C.warnings);
    try std.testing.expectEqual(@as(usize, 2), b.items().len);

    b.append("-DTEST");
    try std.testing.expectEqual(@as(usize, 3), b.items().len);
}
