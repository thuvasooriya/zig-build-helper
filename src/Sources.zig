//! Conditional source file registration helpers
const std = @import("std");

/// A set of source files that can be conditionally added to a compile step.
/// Use when a project has platform-specific or feature-gated source files.
pub const SourceGroup = struct {
    root: std.Build.LazyPath,
    files: []const []const u8,
    flags: []const []const u8,

    /// Add this group's files to a compile step
    pub fn addTo(self: SourceGroup, lib: *std.Build.Step.Compile) void {
        lib.addCSourceFiles(.{
            .root = self.root,
            .files = self.files,
            .flags = self.flags,
        });
    }

    /// Add this group's files only if condition is true
    pub fn addToIf(self: SourceGroup, condition: bool, lib: *std.Build.Step.Compile) void {
        if (condition) self.addTo(lib);
    }
};

/// Builder for accumulating conditional source files with different flag sets.
/// Useful for complex projects with SIMD variants, platform sources, etc.
pub const Bucket = struct {
    lib: *std.Build.Step.Compile,
    root: std.Build.LazyPath,
    base_flags: []const []const u8,

    pub fn init(
        lib: *std.Build.Step.Compile,
        root: std.Build.LazyPath,
        base_flags: []const []const u8,
    ) Bucket {
        return .{
            .lib = lib,
            .root = root,
            .base_flags = base_flags,
        };
    }

    /// Add sources with base flags
    pub fn add(self: *Bucket, files: []const []const u8) void {
        self.lib.addCSourceFiles(.{
            .root = self.root,
            .files = files,
            .flags = self.base_flags,
        });
    }

    /// Add sources if condition is true
    pub fn addIf(self: *Bucket, condition: bool, files: []const []const u8) void {
        if (condition) self.add(files);
    }

    /// Add sources with an extra flag appended to base flags
    pub fn addWithFlag(self: *Bucket, b: *std.Build, files: []const []const u8, extra_flag: []const u8) void {
        const Flags = @import("Flags.zig");
        var flags = Flags.Builder.init(b.allocator);
        flags.appendSlice(self.base_flags);
        flags.append(extra_flag);
        self.lib.addCSourceFiles(.{
            .root = self.root,
            .files = files,
            .flags = flags.items(),
        });
    }

    /// Conditionally add sources with an extra flag
    pub fn addWithFlagIf(self: *Bucket, condition: bool, b: *std.Build, files: []const []const u8, extra_flag: []const u8) void {
        if (condition) self.addWithFlag(b, files, extra_flag);
    }
};
