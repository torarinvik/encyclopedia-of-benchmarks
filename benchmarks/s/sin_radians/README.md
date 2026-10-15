# Sine approximation in radians

Compute the pinned Go sine approximation for a finite radian input. The Go implementation delegates to its Bhaskara-style cosine approximation at `(π/2) - x`; this benchmark preserves that operation and evaluation order rather than calling the platform sine function.

## Contract

- Uses the unary binary64 ABI: `double sin_radians(double radians)`.
- Inputs in `[-1,000,000, 1,000,000]` are accepted. Non-finite and out-of-range values return `-1.0`.
- First form `y = (π / 2) - radians`, then apply the pinned cosine steps in order: scale by `1/(2π)`, subtract `0.25 + floor(y + 0.25)`, multiply by `16 * (abs(y) - 0.5)`, then add `0.225 * y * (abs(y) - 1)`.
- The source approximation is intentionally not replaced by `sin(radians)`. Inputs are bounded so period reduction remains well within finite binary64 precision; the shifted argument ranges from approximately `-999,998.43` to `1,000,001.57`.
- The invalid sentinel `-1.0` may also be a valid approximation result for some in-range inputs; callers distinguish invalidity from the input domain.

## Source semantics

This package follows pinned [TheAlgorithms/Go `Sin`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/sin.go), which returns `Cos((math.Pi / 2) - x)`, and the paired [Go `Cos`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/cos.go), which performs the range reduction and Bhaskara-style correction. The source has no input-bound or invalid-value handling; this benchmark adds the finite ±1e6 boundary for its ABI. This radians-based approximation is a distinct candidate from the Python `sin` source, which uses degrees and a Taylor-series calculation.

## Workload and build

[`workload.json`](workload.json) covers common angles, positive and negative values, shifted one-radian cases, large range reduction, both accepted endpoints, and out-of-range finite inputs. Expected values correspond to the pinned approximation. Cross-language results are compared using relative and absolute tolerances of `1e-12`.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm sin_radians --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/sin_radians/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/s/sin_radians.c`](../../../c/s/sin_radians.c) |
| C3 | [`c3/s/sin_radians.c3`](../../../c3/s/sin_radians.c3) |
| C++ | [`cpp/s/sin_radians.cpp`](../../../cpp/s/sin_radians.cpp) |
| Elisa | [`elisa/s/sin_radians.elisa`](../../../elisa/s/sin_radians.elisa) |
| Nim | [`nim/s/sin_radians.nim`](../../../nim/s/sin_radians.nim) |
| Odin | [`odin/s/sin_radians.odin`](../../../odin/s/sin_radians.odin) |
| Rust | [`rust/s/sin_radians.rs`](../../../rust/s/sin_radians.rs) |
| V | [`v/s/sin_radians.v`](../../../v/s/sin_radians.v) |
| Zig | [`zig/s/sin_radians.zig`](../../../zig/s/sin_radians.zig) |
