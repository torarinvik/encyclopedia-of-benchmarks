# k-medoids with explicit initialization

This benchmark aligns the pinned Python and R implementations on a bounded one-dimensional dataset. It injects the ordered result of random initialization as explicit medoid indices, fixes the metric to Euclidean, and returns both final medoid indices and the assignment vector from the final iteration.

## Contract

Input is a signed 64-bit integer array:

`[point_count, medoid_count, max_iter, initial_medoids[medoid_count]..., points[point_count]...]`

`point_count` is 2 through 8, `medoid_count` is 1 through `min(4, point_count)`, and `max_iter` is 1 through 16. Initial medoids are ordered, distinct, zero-based point indices. Point values are distinct integers in `[-16,16]`; their order in the input is significant. The exact input length is `3 + medoid_count + point_count`, with a maximum valid length of 15 and a maximum parseable length of 16.

The supplied initial medoid order stands in for the selected output of each source's RNG. Python uses `numpy.random.default_rng(...).choice(..., replace=False)` and R uses `sample(..., replace=FALSE)`; their seeded sequences differ, so the benchmark does not attempt to share a seed. R's one-based medoid indices are translated to and from the common zero-based index encoding.

The distance is one-dimensional Euclidean distance, which is the absolute difference between point values. Each iteration assigns every point to its closest medoid, breaking equal-distance ties in favor of the earliest medoid slot. It then replaces each medoid with the first point in input order that minimizes the sum of distances within that point's assigned cluster. Stop after an iteration whose updated medoid list is unchanged, or after `max_iter` updates.

Repeated point values are excluded. Since every medoid is a distinct input point and every point value is unique, each medoid owns its own point at distance zero; all clusters are nonempty. This avoids a source divergence: Python initializes an empty cluster's new medoid to point index zero, while R keeps that cluster's old medoid. Both sources return the assignments computed before the final medoid update when the iteration cap is reached. This benchmark preserves that behavior.

The source Python function returns medoid indices and assignments. The R wrapper returns a fitted model with medoid indices and labels; labels are translated to zero-based medoid-slot indices. This ABI packs both vectors into one nonnegative scalar. Bits 0–11 hold up to four 3-bit medoid indices, with medoid slot `j` at bit `3*j`. Bits 12–27 hold up to eight 2-bit cluster labels, with point `i` at bit `12+2*i`. Decode with:

- `medoid[j] = (result >> (3*j)) & 7`, for `j = 0` through `medoid_count-1`.
- `label[i] = (result >> (12+2*i)) & 3`, for `i = 0` through `point_count-1`.

Valid results range from 0 through 268,435,455. Malformed input or a null input pointer returns `-1`.

The oracle is [`../../k_medoids_oracle.py`](../../k_medoids_oracle.py); [`workload.json`](workload.json) lists the deterministic examples and malformed-input cases.

## Implementations

| Language | Path |
| --- | --- |
| C | [`c/k/k_medoids.c`](../../../c/k/k_medoids.c) |
| C3 | [`c3/k/k_medoids.c3`](../../../c3/k/k_medoids.c3) |
| C++ | [`cpp/k/k_medoids.cpp`](../../../cpp/k/k_medoids.cpp) |
| Elisa | [`elisa/k/k_medoids.elisa`](../../../elisa/k/k_medoids.elisa) |
| Nim | [`nim/k/k_medoids.nim`](../../../nim/k/k_medoids.nim) |
| Odin | [`odin/k/k_medoids.odin`](../../../odin/k/k_medoids.odin) |
| Rust | [`rust/k/k_medoids.rs`](../../../rust/k/k_medoids.rs) |
| V | [`v/k/k_medoids.v`](../../../v/k/k_medoids.v) |
| Zig | [`zig/k/k_medoids.zig`](../../../zig/k/k_medoids.zig) |

## Pinned sources

- Python: [`k_medoids.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/k_medoids.py), which uses Euclidean distances, first-minimum assignment ties, and within-cluster medoid updates.
- R: [`k_medoids.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/machine_learning/k_medoids.r), whose `KMedoids` class supports Euclidean and Manhattan distances and uses the same assignment/update loop for the Euclidean option.
