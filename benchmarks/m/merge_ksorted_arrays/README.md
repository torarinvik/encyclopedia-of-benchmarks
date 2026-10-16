# Merge k sorted arrays

This package ports the pinned Java `mergeKArrays` routine. It places the first item from each nonempty sorted input array into a min-heap, repeatedly removes the smallest item, and inserts the next item from that same array. Duplicate values are retained.

## Contract

- Input is a signed i64 array encoded as `[k, length_0, values..., length_1, values..., ...]`.
- The input must contain 1 to 16 arrays and at most 128 values in total. Each value must be in `[-1,000,000, 1,000,000]`; every array must be nondecreasing. Empty arrays are valid, including when every array is empty.
- Malformed, truncated, extra, out-of-range, or unsorted input returns `-1`.
- The scalar ABI returns a deterministic checksum of the merged value sequence: `sum((zero_based_index + 1) * (value + 1,000,001))`. This adapts Java's returned `int[]` to the scalar benchmark ABI; the maximum absolute result is 16,512,008,256.
- The ports preserve the source's min-heap merge. They order heap ties by value, array index, then element index; ties contain equal values, so this does not change the merged value sequence.

This is separate from [`merge_sorted`](../merge_sorted/README.md), which merges exactly two arrays with the two-pointer method.

## Source and workload

The pinned source is [TheAlgorithms/Java `MergeKSortedArrays.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/MergeKSortedArrays.java). [`workload.json`](workload.json) covers empty arrays, duplicate and negative values, interleaved arrays, maximum array and element counts, malformed encodings, and sortedness/range failures.

Build with the shared `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm merge_ksorted_arrays --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm merge_ksorted_arrays --language rust
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/merge_ksorted_arrays.c`](../../../c/m/merge_ksorted_arrays.c) |
| C3 | [`c3/m/merge_ksorted_arrays.c3`](../../../c3/m/merge_ksorted_arrays.c3) |
| C++ | [`cpp/m/merge_ksorted_arrays.cpp`](../../../cpp/m/merge_ksorted_arrays.cpp) |
| Elisa | [`elisa/m/merge_ksorted_arrays.elisa`](../../../elisa/m/merge_ksorted_arrays.elisa) |
| Nim | [`nim/m/merge_ksorted_arrays.nim`](../../../nim/m/merge_ksorted_arrays.nim) |
| Odin | [`odin/m/merge_ksorted_arrays.odin`](../../../odin/m/merge_ksorted_arrays.odin) |
| Rust | [`rust/m/merge_ksorted_arrays.rs`](../../../rust/m/merge_ksorted_arrays.rs) |
| V | [`v/m/merge_ksorted_arrays.v`](../../../v/m/merge_ksorted_arrays.v) |
| Zig | [`zig/m/merge_ksorted_arrays.zig`](../../../zig/m/merge_ksorted_arrays.zig) |
