# Sum of geometric progression

## Contract

The pinned implementations take `(first_term, common_ratio, num_terms)` and
return the sum of that many terms. For `common_ratio == 1`, they return
`num_terms * first_term`; otherwise they use
`(first_term / (1 - common_ratio)) * (1 - common_ratio^num_terms)`.

The benchmark uses the `float64_triple` ABI. Inputs must be finite, with
`first_term` in `[-1000, 1000]`, `common_ratio` in `[-2, 2]`, and an integral
`num_terms` in `[0, 16]`. Ratios in `(0.9, 1.1)` are excluded except for exactly
`1`, so the pinned formula does not amplify cancellation near its singular
denominator. The result comparison uses an input-scaled tolerance of `1e-9`.

Rust, Julia, and Python use the expression shown above. JavaScript uses the
algebraically equivalent expression
`(first_term * (common_ratio^num_terms - 1)) / (common_ratio - 1)`, which has a
different floating-point operation order; the tolerance accounts for that
rounding difference. The separate `geometric_series` candidate returns the
terms as a sequence rather than their sum.

## Workload and build

[`workload.json`](workload.json) includes the pinned examples, ratio-one and
zero-term cases, fractional and negative ratios, and bounded larger inputs.

Build and record with the three-input float64 ABI:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm sum_of_geometric_progression --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/s/sum_of_geometric_progression/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_geometric_progression.c`](../../../c/s/sum_of_geometric_progression.c) |
| C3 | [`c3/s/sum_of_geometric_progression.c3`](../../../c3/s/sum_of_geometric_progression.c3) |
| C++ | [`cpp/s/sum_of_geometric_progression.cpp`](../../../cpp/s/sum_of_geometric_progression.cpp) |
| Elisa | [`elisa/s/sum_of_geometric_progression.elisa`](../../../elisa/s/sum_of_geometric_progression.elisa) |
| Nim | [`nim/s/sum_of_geometric_progression.nim`](../../../nim/s/sum_of_geometric_progression.nim) |
| Odin | [`odin/s/sum_of_geometric_progression.odin`](../../../odin/s/sum_of_geometric_progression.odin) |
| Rust | [`rust/s/sum_of_geometric_progression.rs`](../../../rust/s/sum_of_geometric_progression.rs) |
| V | [`v/s/sum_of_geometric_progression.v`](../../../v/s/sum_of_geometric_progression.v) |
| Zig | [`zig/s/sum_of_geometric_progression.zig`](../../../zig/s/sum_of_geometric_progression.zig) |

## Pinned sources

- [Rust `sum_of_geometric_progression.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/sum_of_geometric_progression.rs)
- [Julia `sum_of_geometric_progression.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/sum_of_geometric_progression.jl)
- [Python `sum_of_geometric_progression.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sum_of_geometric_progression.py)
- [JavaScript `SumOfGeometricProgression.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SumOfGeometricProgression.js)
