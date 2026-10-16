# Go fast inverse-square-root reciprocal

## Contract

This package follows the Go Sqrt wrapper in
[math/binary/sqrt.go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/sqrt.go)
and its pinned [FastInverseSqrt helper](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/fast_inverse_sqrt.go)
at commit 5ba447ec5ff3d1213de65b92e726ee74c5d5cc19.

The float64_unary input is finite and in [1e-6, 1e6], then rounded to
binary32. The benchmark pins a deterministic binary32 evaluation order for the
0x5f3759df seed, both Newton steps, and the final 1.0f / inverse_root
reciprocal; it widens that binary32 result to binary64. Go's floating-point
specification permits fused operations, so this pinned order describes the
benchmark contract rather than every possible Go compiler and target. Invalid
inputs return -1.0. The domain keeps the cast result positive, normal, and
finite.

This is the approximate reciprocal of the Go fast-inverse-square-root
implementation. It is not the exact square root and is distinct from the
fast_inverse_sqrt_go benchmark, which returns the inverse-root approximation
before the reciprocal.

## Workload and ABI

The workload covers the input bounds, powers and fractions, invalid values,
and representative positive values. Results use relative tolerance 1e-12.
Build with the float64_unary ABI and record using
benchmarks/run_float64_unary.py.

## Implementations

The nine ports are in c/s/sqrt.c, c3/s/sqrt.c3, cpp/s/sqrt.cpp,
elisa/s/sqrt.elisa, nim/s/sqrt.nim, odin/s/sqrt.odin, rust/s/sqrt.rs,
v/s/sqrt.v, and zig/s/sqrt.zig.
