# Secant root finding (MATLAB)

## Contract

This benchmark preserves the pinned MATLAB `secant` routine's residual-based stopping rule for `f(x) = x*x - 3`. Its printed diagnostics are omitted. The packed input uses the `i64_array_float64` ABI and is `[function_selector, a_microunits, b_microunits, tolerance_nanounits, max_updates]`.

- `function_selector` must be `0`, selecting `x*x - 3`.
- `a_microunits` represents `a / 1e6` and must be in `1,000,000..=1,500,000`.
- `b_microunits` represents `b / 1e6` and must be in `1,600,000..=2,000,000`; `a` must be less than `b`.
- `tolerance_nanounits` represents `tolerance / 1e9` and must be in `1..=100,000`.
- `max_updates` must be in `0..=32`.

Starting from `(a,b)`, each update applies the MATLAB secant formula. The current second point is returned as soon as `abs(f(x)) <= tolerance`. If the residual still exceeds tolerance after the allowed updates, the result is the finite sentinel `-1e300`. Invalid input also returns `-1e300`. With zero updates, `b` is returned only when its residual already meets tolerance. Since `f` is strictly increasing on the positive bounded domain and `a < b`, the initial secant denominator is nonzero; the bounded iteration converges toward the positive root.

The workload compares binary64 results with absolute tolerance `1e-12` and zero relative tolerance. Cases and expected results are in [`workload.json`](workload.json); the independent expected-result logic is in [`secant_oracle.py`](../../secant_oracle.py).

Build, record, and verify with `i64_array_float64`:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm secant --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/secant/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm secant
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/secant.c`](../../../c/s/secant.c) |
| C3 | [`c3/s/secant.c3`](../../../c3/s/secant.c3) |
| C++ | [`cpp/s/secant.cpp`](../../../cpp/s/secant.cpp) |
| Elisa | [`elisa/s/secant.elisa`](../../../elisa/s/secant.elisa) |
| Nim | [`nim/s/secant.nim`](../../../nim/s/secant.nim) |
| Odin | [`odin/s/secant.odin`](../../../odin/s/secant.odin) |
| Rust | [`rust/s/secant.rs`](../../../rust/s/secant.rs) |
| V | [`v/s/secant.v`](../../../v/s/secant.v) |
| Zig | [`zig/s/secant.zig`](../../../zig/s/secant.zig) |

## TheAlgorithms reference

- [MATLAB `secant.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/arithmetic_analysis/secant.m)
