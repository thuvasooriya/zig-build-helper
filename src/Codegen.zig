//! Host tool building and code generation helpers
const std = @import("std");

/// Build an executable that runs on the host (build machine).
/// Useful for code generators that must run during the build.
pub fn addHostTool(
    b: *std.Build,
    name: []const u8,
    root_source_file: std.Build.LazyPath,
) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = root_source_file,
            .target = b.graph.host,
        }),
    });
}

/// Run a host tool and capture its stdout as a generated file.
/// Returns a LazyPath to the output file.
pub fn runHostTool(
    b: *std.Build,
    tool: *std.Build.Step.Compile,
    args: []const []const u8,
    output_name: []const u8,
) std.Build.LazyPath {
    const run = b.addRunArtifact(tool);
    for (args) |arg| run.addArg(arg);
    return run.addOutputFileArg(output_name);
}

/// Run a system command and capture stdout as a generated file.
/// Useful for running python, bison, flex, etc.
pub fn runSystemTool(
    b: *std.Build,
    argv: []const []const u8,
    output_name: []const u8,
) struct { run: *std.Build.Step.Run, output: std.Build.LazyPath } {
    const run = b.addSystemCommand(argv);
    const output = run.addOutputFileArg(output_name);
    return .{ .run = run, .output = output };
}

/// Run a system command and capture an output directory.
pub fn runSystemToolDir(
    b: *std.Build,
    argv: []const []const u8,
    output_dir_name: []const u8,
) struct { run: *std.Build.Step.Run, dir: std.Build.LazyPath } {
    const run = b.addSystemCommand(argv);
    const dir = run.addOutputDirectoryArg(output_dir_name);
    return .{ .run = run, .dir = dir };
}
