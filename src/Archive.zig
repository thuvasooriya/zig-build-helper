const std = @import("std");

pub fn create(
    b: *std.Build,
    name: []const u8,
    is_windows: bool,
    output_dir: []const u8,
) *std.Build.Step.Run {
    const install_path = b.pathJoin(&.{ output_dir, name });

    if (is_windows) {
        const zip_cmd = b.addSystemCommand(&.{
            "zip",                             "-r",
            b.fmt("{s}.zip", .{install_path}), name,
        });
        zip_cmd.cwd = .{ .cwd_relative = output_dir };
        return zip_cmd;
    } else {
        const tar_cmd = b.addSystemCommand(&.{
            "tar",                                "-czvf",
            b.fmt("{s}.tar.gz", .{install_path}), name,
        });
        tar_cmd.cwd = .{ .cwd_relative = output_dir };
        return tar_cmd;
    }
}
