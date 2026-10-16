# Is automorphic

## Contract

This package follows the pinned Go source
[isautomorphic.go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/isautomorphic.go)
at commit 5ba447ec5ff3d1213de65b92e726ee74c5d5cc19. It uses the scalar i64 ABI
and returns 1 when the source predicate is true and 0 otherwise.

For nonnegative n, the predicate checks whether n squared ends in the decimal
digits of n. Zero is true, and negative values return false. The valid input
range is [-3037000499, 3037000499]. Its positive maximum is floor(sqrt(INT64_MAX)),
so the source's direct n*n operation remains inside signed 64-bit. Inputs
outside this range return -1.

This is source-faithful to Go's direct square-and-digit loop. The existing
automorphic_number package implements the same predicate over the full signed
64-bit range using modular multiplication to avoid overflow; this package
benchmarks the bounded direct-square implementation.

The workload includes automorphic and neighboring non-automorphic values,
negative inputs, both safe square bounds, and the out-of-range sentinel.

## Implementations

The nine ports are in c/i/isautomorphic.c, c3/i/isautomorphic.c3,
cpp/i/isautomorphic.cpp, elisa/i/isautomorphic.elisa, nim/i/isautomorphic.nim,
odin/i/isautomorphic.odin, rust/i/isautomorphic.rs, v/i/isautomorphic.v, and
zig/i/isautomorphic.zig. Build with the scalar ABI and record using
benchmarks/run_scalar.py.
