# Geometric sequence and mean

Port the two deterministic functions in the pinned Python source: geometric-sequence detection and geometric mean.

## Contract

- The `i64_array_float64` ABI accepts `[operation, value_0, ..., value_n]`.
- Operation `0` checks a nonempty sequence of 1 through 16 integers in `[-100,100]`. It returns `1.0` for a geometric sequence and `0.0` otherwise. A one-element sequence is geometric; zero divisors follow the source's caught `ZeroDivisionError` behavior and return false.
- Operation `1` computes the geometric mean of 1 through 7 integers in `[0,100]`, using the source's product-then-power expression `pow(product, 1/count)`. The bounds keep the integer product exact and within signed 64-bit range.
- Malformed or out-of-domain inputs return `-1e300`. The output tolerance is absolute and relative `1e-12`.

## Source semantics

The source file contains `is_geometric_series` and `geometric_mean`. The former compares adjacent Python true-division ratios exactly and returns true for any one-element list; zero division is caught and yields false. The latter multiplies the list values first and raises the product to the reciprocal of the list length. This is separate from the `geometric_series` source, which generates a term sequence.

## Workload and reproduction

[`workload.json`](workload.json) includes positive and negative common ratios, constant and one-element sequences, zero divisors, non-geometric sequences, geometric means, zero-valued means, and malformed selectors/values.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm geometric --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/geometric/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/geometric.c`](../../../c/g/geometric.c) |
| C3 | [`c3/g/geometric.c3`](../../../c3/g/geometric.c3) |
| C++ | [`cpp/g/geometric.cpp`](../../../cpp/g/geometric.cpp) |
| Elisa | [`elisa/g/geometric.elisa`](../../../elisa/g/geometric.elisa) |
| Nim | [`nim/g/geometric.nim`](../../../nim/g/geometric.nim) |
| Odin | [`odin/g/geometric.odin`](../../../odin/g/geometric.odin) |
| Rust | [`rust/g/geometric.rs`](../../../rust/g/geometric.rs) |
| V | [`v/g/geometric.v`](../../../v/g/geometric.v) |
| Zig | [`zig/g/geometric.zig`](../../../zig/g/geometric.zig) |

## Pinned source

- [Python `geometric.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/geometric.py)
