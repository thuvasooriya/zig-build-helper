//! Config header generation utilities
const std = @import("std");

/// Create a header wrapper that redirects includes (e.g., "webp/config.h" -> "src/webp/config.h")
pub fn createHeaderWrapper(
    b: *std.Build,
    wrapper_path: []const u8,
    target_include: []const u8,
) std.Build.LazyPath {
    const wf = b.addWriteFiles();
    const content = b.fmt("#include \"{s}\"\n", .{target_include});
    _ = wf.add(wrapper_path, content);
    return wf.getDirectory();
}

pub fn boolToInt(b: bool) i32 {
    return if (b) 1 else 0;
}

pub fn boolToOptInt(b: bool) ?i32 {
    return if (b) @as(i32, 1) else null;
}

/// Builder for generating C config headers via #define directives.
/// Useful for projects that need autoconf-style config.h generation.
/// Accumulates #define lines and produces the final header content.
pub const HeaderBuilder = struct {
    buffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HeaderBuilder {
        return .{
            .buffer = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HeaderBuilder) void {
        self.buffer.deinit(self.allocator);
    }

    /// Add a numeric define: #define KEY VALUE
    pub fn add(self: *HeaderBuilder, key: []const u8, value: anytype) void {
        const writer = self.buffer.writer(self.allocator);
        switch (@TypeOf(value)) {
            []const u8 => writer.print("#define {s} {s}\n", .{ key, value }) catch @panic("OOM"),
            i32, u32, usize, comptime_int => {
                var buf: [32]u8 = undefined;
                const v_str = std.fmt.bufPrint(&buf, "{}", .{value}) catch unreachable;
                writer.print("#define {s} {s}\n", .{ key, v_str }) catch @panic("OOM");
            },
            else => @compileError("Unsupported type: use addStr or addRaw for other types"),
        }
    }

    /// Add a quoted string define: #define KEY "VALUE"
    pub fn addStr(self: *HeaderBuilder, key: []const u8, value: []const u8) void {
        self.buffer.writer(self.allocator).print("#define {s} \"{s}\"\n", .{ key, value }) catch @panic("OOM");
    }

    /// Add a raw identifier define: #define KEY VALUE (no quoting)
    pub fn addRaw(self: *HeaderBuilder, key: []const u8, value: []const u8) void {
        self.buffer.writer(self.allocator).print("#define {s} {s}\n", .{ key, value }) catch @panic("OOM");
    }

    /// Add a boolean define: #define KEY 1
    pub fn define(self: *HeaderBuilder, key: []const u8) void {
        self.buffer.writer(self.allocator).print("#define {s} 1\n", .{key}) catch @panic("OOM");
    }

    /// Conditionally define if condition is true
    pub fn defineIf(self: *HeaderBuilder, condition: bool, key: []const u8) void {
        if (condition) self.define(key);
    }

    /// Define multiple keys at once (all set to 1)
    pub fn defineAll(self: *HeaderBuilder, keys: []const []const u8) void {
        for (keys) |key| self.define(key);
    }

    /// Finalize and return the header content. Caller owns the memory.
    pub fn finish(self: *HeaderBuilder) []const u8 {
        return self.buffer.toOwnedSlice(self.allocator) catch @panic("OOM");
    }

    /// Write the header directly to a WriteFile step. Returns the WriteFile for further use.
    pub fn emit(self: *HeaderBuilder, b: *std.Build, path: []const u8) *std.Build.Step.WriteFile {
        const wf = b.addWriteFiles();
        _ = wf.add(path, self.finish());
        return wf;
    }
};

test "boolToInt" {
    try std.testing.expectEqual(@as(i32, 1), boolToInt(true));
    try std.testing.expectEqual(@as(i32, 0), boolToInt(false));
}

test "boolToOptInt" {
    try std.testing.expectEqual(@as(?i32, 1), boolToOptInt(true));
    try std.testing.expectEqual(@as(?i32, null), boolToOptInt(false));
}

test "HeaderBuilder basic usage" {
    const allocator = std.testing.allocator;
    var hb = HeaderBuilder.init(allocator);
    defer hb.deinit();

    hb.define("HAVE_STDIO_H");
    hb.add("SIZEOF_INT", 4);
    hb.addStr("PACKAGE", "mylib");
    hb.addRaw("SELECT_TYPE", "(fd_set *)");
    hb.defineIf(true, "HAVE_UNISTD_H");
    hb.defineIf(false, "HAVE_WINDOWS_H");

    const result = hb.finish();
    defer allocator.free(result);

    try std.testing.expect(std.mem.indexOf(u8, result, "#define HAVE_STDIO_H 1\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "#define SIZEOF_INT 4\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "#define PACKAGE \"mylib\"\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "#define SELECT_TYPE (fd_set *)\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "#define HAVE_UNISTD_H 1\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "HAVE_WINDOWS_H") == null);
}

test "HeaderBuilder defineAll" {
    const allocator = std.testing.allocator;
    var hb = HeaderBuilder.init(allocator);
    defer hb.deinit();

    hb.defineAll(&.{ "A", "B", "C" });
    const result = hb.finish();
    defer allocator.free(result);

    try std.testing.expect(std.mem.indexOf(u8, result, "#define A 1\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "#define B 1\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "#define C 1\n") != null);
}
