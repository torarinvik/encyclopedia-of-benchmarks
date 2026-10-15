# Cosine approximation

Approximates the cosine of an angle in radians with a Bhaskara-style polynomial and range reduction.

## Contract

- Uses the unary binary64 ABI: `double cos(double radians)`.
- Finite inputs in `[-1,000,000, 1,000,000]` are accepted. Non-finite and out-of-range values return `-1.0`.
- Returns the pinned approximation in this operation order: normalize by `1/(2π)`, subtract `0.25 + floor(x + 0.25)`, apply `16 * (abs(x) - 0.5)`, then add the `0.225 * x * (abs(x) - 1)` correction.
- Results are compared with absolute and relative tolerances of `1e-12` to account for binary64 library rounding.

## Source semantics

The benchmark follows pinned [TheAlgorithms Go `cos.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/cos.go). Its input is in radians. It scales by `1/(2π)` and reduces the period with `x -= 0.25 + floor(x + 0.25)`, then evaluates the Bhaskara approximation and its `0.225` correction in the same order. The source has no special-case branches; it returns `1` at zero, approximately zero at ±π/2, and `-1` at ±π. The benchmark bounds finite inputs to ±1e6 and maps non-finite or wider values to `-1.0`.

## Workload and build

[`workload.json`](workload.json) includes zero, common angles, positive and negative arguments, large range-reduction cases, and invalid bounds. Build and record with the float64 unary ABI:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm cos --language c
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/c/cos/c/build.json
```

The nine implementations are in `c/c/cos.c`, `c3/c/cos.c3`, `cpp/c/cos.cpp`, `elisa/c/cos.elisa`, `nim/c/cos.nim`, `odin/c/cos.odin`, `rust/c/cos.rs`, `v/c/cos.v`, and `zig/c/cos.zig`.
