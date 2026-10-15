# Arithmetic–geometric mean

Iterate the arithmetic and geometric means of two binary64 values until the arithmetic mean stops changing. This follows the pinned JavaScript `agm` routine on a bounded nonnegative domain.

## Contract

- Inputs are ordered finite binary64 values `[a, g]`, each in `[0, 1,000,000]`.
- Return the common limit of the repeated updates `a = (a + g) / 2` and `g = sqrt(a * g)`. Each update uses both prior values. The source stops when the new arithmetic mean equals its previous value.
- Equal inputs return that value immediately, matching the source shortcut. Zero and positive inputs are supported; `[0, 1]` converges to `0`.
- Negative values and values above the bound return `-1.0` as the shared invalid-input sentinel. Non-finite inputs are outside the ABI's finite-input domain.
- The source's `Infinity`/zero and negative-zero special cases do not change the numeric result on this bounded domain. The iteration uses constant auxiliary space.

This is distinct from [`geometric_mean`](../../g/geometric_mean/README.md), which takes an arbitrary-length list and computes a single nth root of its product. The pinned [JavaScript `ArithmeticGeometricMean.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ArithmeticGeometricMean.js) takes exactly two values and repeats both mean updates.

## Workload and build

[`workload.json`](workload.json) covers equality, zero, a nontrivial positive pair, the maximum bounded value, and invalid negative or oversized inputs. All nine ports use the shared `float64_pair` ABI with a relative tolerance for converged binary64 results.

```sh
python3 benchmarks/build_abi.py --family float64_pair --algorithm arithmetic_geometric_mean --language rust
python3 benchmarks/run_float64_pair.py --build-manifest build/float64_pair/a/arithmetic_geometric_mean/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/arithmetic_geometric_mean.c`](../../../c/a/arithmetic_geometric_mean.c) |
| C3 | [`c3/a/arithmetic_geometric_mean.c3`](../../../c3/a/arithmetic_geometric_mean.c3) |
| C++ | [`cpp/a/arithmetic_geometric_mean.cpp`](../../../cpp/a/arithmetic_geometric_mean.cpp) |
| Elisa | [`elisa/a/arithmetic_geometric_mean.elisa`](../../../elisa/a/arithmetic_geometric_mean.elisa) |
| Nim | [`nim/a/arithmetic_geometric_mean.nim`](../../../nim/a/arithmetic_geometric_mean.nim) |
| Odin | [`odin/a/arithmetic_geometric_mean.odin`](../../../odin/a/arithmetic_geometric_mean.odin) |
| Rust | [`rust/a/arithmetic_geometric_mean.rs`](../../../rust/a/arithmetic_geometric_mean.rs) |
| V | [`v/a/arithmetic_geometric_mean.v`](../../../v/a/arithmetic_geometric_mean.v) |
| Zig | [`zig/a/arithmetic_geometric_mean.zig`](../../../zig/a/arithmetic_geometric_mean.zig) |
