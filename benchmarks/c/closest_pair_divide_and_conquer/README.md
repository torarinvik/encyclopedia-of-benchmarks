# Closest Pair by Divide and Conquer

This benchmark covers the planar closest-pair problem using x-ordered recursive partitions and a y-ordered strip scan. The ports use original input indices as point identities, split strip points by x-rank so equal x-coordinates stay in the correct recursive half, and compare every strip successor whose y-distance can still tie or improve the best pair.

## Contract

- Input is an even-length array of signed 64-bit integers: `(x0, y0, x1, y1, ...)`.
- There are at most 1,024 points, and each coordinate is in `[-1,000,000,000, 1,000,000,000]`. This bound keeps squared Euclidean distances exact in signed 64-bit arithmetic.
- Return `2` and write the two original point indices as signed 32-bit little-endian integers. The smaller index comes first. Among equal-distance pairs, return the lexicographically smallest index pair.
- Return `0` with no output for zero or one point. Invalid length or coordinates return `-1`. Insufficient output capacity returns `-2` without writing.
- Time complexity is `O(n log n)`; sorting and recursive y-partitioning use `O(n log n)` auxiliary storage in total.

The integer coordinate domain is a bounded exact subset of the upstream binary64 `Point` domain. Comparing squared distances avoids square roots while preserving the closest pair. The deterministic index tie rule makes equal-distance cases portable.

[`workload.json`](workload.json) includes duplicate x-coordinates across recursive partitions, equal-distance ties, duplicate points, empty and single-point inputs, invalid inputs, and a 1,024-point case.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm closest_pair_divide_and_conquer --language rust
```

## Upstream references

- [TheAlgorithms/Rust `closest_points.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/geometry/closest_points.rs)
- [TheAlgorithms/Java `ClosestPair.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/ClosestPair.java)
- [TheAlgorithms/Python `closest_pair_of_points.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/closest_pair_of_points.py)

The Rust source partitions its y-ordered points using `x < mid_x`, which can disagree with its rank-based x split when several points share the midpoint x-coordinate. Its base case also indexes from zero rather than the current recursive range, and it checks at most seven strip successors. The Python source passes its y-sorted array as the x-sorted input on the right recursion. The Java source keeps the current minimum and strip count in static mutable fields, so results can leak between calls. This benchmark preserves the shared divide-and-conquer method while correcting those defects.
