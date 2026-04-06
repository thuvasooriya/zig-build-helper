const std = @import("std");
const root = @import("src/root.zig");

// re-export for consumer build.zig files that @import("zig_build_helper")
pub const Platform = root.Platform;
pub const Simd = root.Simd;
pub const Flags = root.Flags;
pub const Config = root.Config;
pub const Ci = root.Ci;
pub const Archive = root.Archive;
pub const Dependencies = root.Dependencies;
pub const Codegen = root.Codegen;
pub const Sources = root.Sources;
pub const checkZigVersion = root.checkZigVersion;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("zig_build_helper", .{
        .root_source_file = b.path("src/root.zig"),
    });

    const mod_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run module tests");
    test_step.dependOn(&run_mod_tests.step);
}
