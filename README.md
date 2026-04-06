# zig-build-helper

Build system utilities for Zig-based C/C++ project packaging.

This library provides reusable components for packaging C/C++ libraries with Zig's build system.

## Features

- **Platform detection**: Unified detection of OS, architecture, and ABI
- **SIMD detection**: Automatic detection of x86 (SSE, AVX) and ARM (NEON) features
- **CI configuration**: Standard CI matrix setup for cross-compilation
- **Config header generation**: Programmatic C config header creation
- **Dependency helpers**: Support for static, system-linked, or optional dependencies

## License

MIT License
