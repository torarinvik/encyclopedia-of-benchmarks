# Brent's method

Find a bracketed root with the pinned Python Brent implementation. It chooses inverse quadratic interpolation when three function values differ, otherwise a secant step, and falls back to bisection when the proposed step fails the source's safeguards.

## Contract

The `float64_triple` input is `[function_id, left, right]`. To make the source's callback interface portable, the benchmark supplies three deterministic functions:

| ID | Function |
| --- | --- |
| 0 | `x^3 - x - 2` |
| 1 | `x^2 + 1` |
| 2 | `x^2 - 4x + 3` |

The function ID must be exactly `0`, `1`, or `2`; endpoints must be finite values in `[-4, 4]` with `left < right`. The ports use the source defaults `tol=1e-8` and `max_iter=100`, preserve its interpolation and fallback order, and return the final right endpoint. Invalid inputs and intervals without opposite-sign endpoint values return `-1e300`.

## Workload and build

[`workload.json`](workload.json) covers interpolation and fallback convergence, multiple roots, a bracket with no sign change, and invalid function and interval inputs.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm brent_method --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/b/brent_method/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/brent_method.c`](../../../c/b/brent_method.c) |
| C3 | [`c3/b/brent_method.c3`](../../../c3/b/brent_method.c3) |
| C++ | [`cpp/b/brent_method.cpp`](../../../cpp/b/brent_method.cpp) |
| Elisa | [`elisa/b/brent_method.elisa`](../../../elisa/b/brent_method.elisa) |
| Nim | [`nim/b/brent_method.nim`](../../../nim/b/brent_method.nim) |
| Odin | [`odin/b/brent_method.odin`](../../../odin/b/brent_method.odin) |
| Rust | [`rust/b/brent_method.rs`](../../../rust/b/brent_method.rs) |
| V | [`v/b/brent_method.v`](../../../v/b/brent_method.v) |
| Zig | [`zig/b/brent_method.zig`](../../../zig/b/brent_method.zig) |

## Pinned source

- Python [`brent_method.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/brent_method.py)
