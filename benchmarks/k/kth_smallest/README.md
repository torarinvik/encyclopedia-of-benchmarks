# K-th Smallest by Quickselect

Return the value at one-based rank `k` in an array, using the pinned Rust quickselect method. The method repeatedly partitions around the last element in the active range and continues only in the range containing the requested rank.

## Contract

- The packed input is `[n, k, values...]`, with `n` from 1 through 256, `k` from 1 through `n`, and each value a signed 32-bit integer.
- Duplicate values count as separate positions. The scalar result is the value that would appear at zero-based index `k - 1` after sorting the values ascending.
- Invalid packed input returns `INT64_MIN`, a sentinel outside the valid signed 32-bit result domain.
- The Rust source mutates its input while partitioning and allocates no auxiliary array. The read-only array ABI requires a bounded working copy; each port performs the same in-place quickselect on that copy, leaving the packed input intact.
- The source returns `None` for an empty array and does not validate out-of-range ranks. The benchmark excludes those ranks from the valid domain and maps empty, malformed, or invalid-rank inputs to the sentinel.

The pinned [`kth_smallest.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/kth_smallest.rs) imports `partition` from [`quick_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/quick_sort.rs). The ports preserve that last-element partition's scan, including its `j > 0` boundary, and equal-value swap rules. Expected time is O(n) on average and O(n²) in the worst case; the bounded implementation uses O(n) space for the ABI copy.

The sibling [`kth_smallest_heap.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/kth_smallest_heap.rs) uses a max heap and does not mutate its input. It has the same valid rank result but a distinct method. [`kth_smallest_bst`](../kth_smallest_bst/README.md) ranks nodes in a BST, while the existing kth-largest packages select the opposite order statistic.

[`workload.json`](workload.json) covers boundary ranks, duplicate and negative values, sorted inputs, malformed packed input, and the maximum supported length.

| Language | Source |
| --- | --- |
| C | [`c/k/kth_smallest.c`](../../../c/k/kth_smallest.c) |
| C3 | [`c3/k/kth_smallest.c3`](../../../c3/k/kth_smallest.c3) |
| C++ | [`cpp/k/kth_smallest.cpp`](../../../cpp/k/kth_smallest.cpp) |
| Elisa | [`elisa/k/kth_smallest.elisa`](../../../elisa/k/kth_smallest.elisa) |
| Nim | [`nim/k/kth_smallest.nim`](../../../nim/k/kth_smallest.nim) |
| Odin | [`odin/k/kth_smallest.odin`](../../../odin/k/kth_smallest.odin) |
| Rust | [`rust/k/kth_smallest.rs`](../../../rust/k/kth_smallest.rs) |
| V | [`v/k/kth_smallest.v`](../../../v/k/kth_smallest.v) |
| Zig | [`zig/k/kth_smallest.zig`](../../../zig/k/kth_smallest.zig) |
