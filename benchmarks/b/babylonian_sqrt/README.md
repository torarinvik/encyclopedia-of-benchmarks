# Babylonian square root

Approximate a nonnegative value's square root with the pinned Julia implementation's Babylonian iteration. The source uses `tolerance = 1e-6` and defaults the initial guess to half the input.

## Contract

- Inputs in `[0, 1,000,000]` are supported. Negative inputs throw a `DomainError` in Julia and map to `-1.0`; values above the benchmark bound also return `-1.0`.
- For valid input `S`, initialize `xn = S / 2` and update with `xn = 0.5 * (xn + S / xn)` while `1e-6 <= abs(xn * xn - S)`. The zero input returns zero without entering the loop.
- The algorithm returns its approximation when the squared residual is below the source tolerance. The benchmark compares the exact iterative result with relative and absolute tolerances of `1e-12` to accommodate small binary64 rounding differences between ports.
- The fixed iteration count is bounded on the supported input range; auxiliary space is constant.

[`workload.json`](workload.json) covers zero, tiny positive values where the source tolerance affects the result, source examples, a non-square irrational result, the upper bound, and invalid inputs.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm babylonian_sqrt --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/b/babylonian_sqrt/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/babylonian_sqrt.c`](../../../c/b/babylonian_sqrt.c) |
| C3 | [`c3/b/babylonian_sqrt.c3`](../../../c3/b/babylonian_sqrt.c3) |
| C++ | [`cpp/b/babylonian_sqrt.cpp`](../../../cpp/b/babylonian_sqrt.cpp) |
| Elisa | [`elisa/b/babylonian_sqrt.elisa`](../../../elisa/b/babylonian_sqrt.elisa) |
| Nim | [`nim/b/babylonian_sqrt.nim`](../../../nim/b/babylonian_sqrt.nim) |
| Odin | [`odin/b/babylonian_sqrt.odin`](../../../odin/b/babylonian_sqrt.odin) |
| Rust | [`rust/b/babylonian_sqrt.rs`](../../../rust/b/babylonian_sqrt.rs) |
| V | [`v/b/babylonian_sqrt.v`](../../../v/b/babylonian_sqrt.v) |
| Zig | [`zig/b/babylonian_sqrt.zig`](../../../zig/b/babylonian_sqrt.zig) |

## Upstream source

- [TheAlgorithms/Julia `babylonian_sqrt.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/babylonian_sqrt.jl)
