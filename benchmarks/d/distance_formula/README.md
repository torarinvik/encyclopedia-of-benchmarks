# Distance formula

Compute the Euclidean distance using the coordinate expression in the pinned Java source.

## Contract

- The `i64_array_float64` ABI accepts `[x1, y1, x2, y2]` and returns a binary64 distance.
- Each integer coordinate is bounded to `[-1,000,000, 1,000,000]`.
- The benchmark preserves the source expression `sqrt((x2 - x1)^2 + (y2 - x1)^2)`, including its use of `x1` in the second term.
- Invalid length or coordinate bounds return `-1e300`. Valid results use relative and absolute tolerance `1e-12`.

## Source semantics

This ports the `euclideanDistance` method from pinned [TheAlgorithms Java `DistanceFormula.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/DistanceFormula.java). The source computes `dY = y2 - x1` rather than `y2 - y1`; the workload includes a case where that distinction changes the result. The bounded integer coordinates are a normalized subset of its double-valued API. The class also defines Manhattan, Hamming, and Minkowski methods; the catalog maps these to established benchmarks on matching bounded domains, with the Hamming mapping restricted to binary vectors.

## Workload

[`workload.json`](workload.json) covers the documented 3-4-5 example, negative coordinates, zero distance, a source-mismatch case, the coordinate bounds, and invalid packed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/distance_formula.c`](../../../c/d/distance_formula.c) |
| C3 | [`c3/d/distance_formula.c3`](../../../c3/d/distance_formula.c3) |
| C++ | [`cpp/d/distance_formula.cpp`](../../../cpp/d/distance_formula.cpp) |
| Elisa | [`elisa/d/distance_formula.elisa`](../../../elisa/d/distance_formula.elisa) |
| Nim | [`nim/d/distance_formula.nim`](../../../nim/d/distance_formula.nim) |
| Odin | [`odin/d/distance_formula.odin`](../../../odin/d/distance_formula.odin) |
| Rust | [`rust/d/distance_formula.rs`](../../../rust/d/distance_formula.rs) |
| V | [`v/d/distance_formula.v`](../../../v/d/distance_formula.v) |
| Zig | [`zig/d/distance_formula.zig`](../../../zig/d/distance_formula.zig) |

The package uses the `i64_array_float64` benchmark ABI.
