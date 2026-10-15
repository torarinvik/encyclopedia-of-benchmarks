# Minkowski distance

Compute the order-`p` Minkowski distance between two points with the same dimension, following the pinned Python formula.

## Contract

- The packed signed 64-bit input is `[n, p, point_a[0..n), point_b[0..n)]`.
- Accept dimensions `n` from 0 through 8, order `p` from 3 through 6, and every coordinate in `[-100, 100]`. Require an exact packed length of `2 + 2*n`.
- Return `(Σ |a[i] - b[i]|^p)^(1/p)` as binary64. The coordinate differences are at most 200; the largest possible integer sum is `8 * 200^6 = 512,000,000,000,000`, below `2^53`, so all products and the sum are exact before taking the root. Empty, equal-dimensional points are accepted and return `0.0`.
- Return `-1e300` for malformed packed inputs or values outside the benchmark bounds. The source raises for `p < 1` and for mismatched dimensions; this ABI maps those cases to the sentinel. Orders 1 and 2 are valid in the general source but excluded here to keep this benchmark distinct from Manhattan and Euclidean distance.
- The computation takes `O(n*p)` time and `O(1)` auxiliary space.

## Source and related algorithms

The pinned [Python `minkowski_distance.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/minkowski_distance.py) takes `(point_a, point_b, order)` and computes `(sum(abs(a-b)**order))**(1/order)`. The separately cataloged [C# `Minkowski.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/LinearAlgebra/Distances/Minkowski.cs) uses the same argument order and formula; its candidate ID `minkowski` is the same algorithm and should be reviewed as a catalog alias. This package uses the Python candidate ID `minkowski_distance`. The supported orders exclude the Manhattan (`p=1`) and Euclidean (`p=2`) special cases.

## Workload and build

[`workload.json`](workload.json) covers orders 3 through 6, one and multiple dimensions, zero-dimensional points, equal points, malformed layouts, and out-of-domain inputs. All nine ports use the shared `i64_array_float64` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm minkowski_distance --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/minkowski_distance/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/minkowski_distance.c`](../../../c/m/minkowski_distance.c) |
| C3 | [`c3/m/minkowski_distance.c3`](../../../c3/m/minkowski_distance.c3) |
| C++ | [`cpp/m/minkowski_distance.cpp`](../../../cpp/m/minkowski_distance.cpp) |
| Elisa | [`elisa/m/minkowski_distance.elisa`](../../../elisa/m/minkowski_distance.elisa) |
| Nim | [`nim/m/minkowski_distance.nim`](../../../nim/m/minkowski_distance.nim) |
| Odin | [`odin/m/minkowski_distance.odin`](../../../odin/m/minkowski_distance.odin) |
| Rust | [`rust/m/minkowski_distance.rs`](../../../rust/m/minkowski_distance.rs) |
| V | [`v/m/minkowski_distance.v`](../../../v/m/minkowski_distance.v) |
| Zig | [`zig/m/minkowski_distance.zig`](../../../zig/m/minkowski_distance.zig) |
