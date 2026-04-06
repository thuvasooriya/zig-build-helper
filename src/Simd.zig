//! SIMD feature detection for x86 and ARM architectures
const std = @import("std");

const Simd = @This();

sse2: bool = false,
sse3: bool = false,
ssse3: bool = false,
sse4_1: bool = false,
sse4_2: bool = false,
avx: bool = false,
avx2: bool = false,
avx512f: bool = false,
neon: bool = false,

/// Detect SIMD features from target
pub fn detect(target: std.Target, enabled: bool) Simd {
    if (!enabled) return .{};

    const is_x86 = target.cpu.arch == .x86 or target.cpu.arch == .x86_64;
    const is_arm32 = switch (target.cpu.arch) {
        .arm, .armeb, .thumb, .thumbeb => true,
        else => false,
    };
    const is_arm64 = target.cpu.arch == .aarch64 or target.cpu.arch == .aarch64_be;

    if (is_x86) {
        return .{
            .sse2 = hasX86Feature(target, .sse2),
            .sse3 = hasX86Feature(target, .sse3),
            .ssse3 = hasX86Feature(target, .ssse3),
            .sse4_1 = hasX86Feature(target, .sse4_1),
            .sse4_2 = hasX86Feature(target, .sse4_2),
            .avx = hasX86Feature(target, .avx),
            .avx2 = hasX86Feature(target, .avx2),
            .avx512f = hasX86Feature(target, .avx512f),
            .neon = false,
        };
    } else if (is_arm32) {
        return .{ .neon = hasArmFeature(target, .neon) };
    } else if (is_arm64) {
        return .{ .neon = hasArm64Feature(target, .neon) };
    }
    return .{};
}

fn hasX86Feature(target: std.Target, feature: std.Target.x86.Feature) bool {
    return target.cpu.features.isEnabled(@intFromEnum(feature));
}

fn hasArmFeature(target: std.Target, feature: std.Target.arm.Feature) bool {
    return target.cpu.features.isEnabled(@intFromEnum(feature));
}

fn hasArm64Feature(target: std.Target, feature: std.Target.aarch64.Feature) bool {
    return target.cpu.features.isEnabled(@intFromEnum(feature));
}
