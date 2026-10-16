# Optimal file merging

Given file sizes, repeatedly merge the two smallest files. Each merge costs the sum of their sizes; the result is the minimum total merge cost.

## Contract

- The `i64_array_scalar` input is `[count, size0, ...]`; count is 0 through 32 and each size is 0 through 1,000,000.
- The packed input length must equal `count + 1`. Invalid input returns -1.
- The result is the sum of every merged size. Empty and singleton inputs return 0. Bounds keep Java `int` source arithmetic within range.
- The implementation uses an in-place minimum scan over at most 32 active sizes. The pinned Java source uses a priority queue; the pinned Python source scans a list. Both select the same two minima and produce the same total.

[`workload.json`](workload.json) covers the pinned example, equal and zero sizes, singleton and empty inputs, bounds, and malformed inputs.

The canonical source is [Java `OptimalFileMerging`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/OptimalFileMerging.java). The same greedy recurrence appears in [Python `optimal_merge_pattern`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/optimal_merge_pattern.py).

## Implementations

- C: [`c/o/optimal_file_merging.c`](../../../c/o/optimal_file_merging.c)
- C3: [`c3/o/optimal_file_merging.c3`](../../../c3/o/optimal_file_merging.c3)
- C++: [`cpp/o/optimal_file_merging.cpp`](../../../cpp/o/optimal_file_merging.cpp)
- Elisa: [`elisa/o/optimal_file_merging.elisa`](../../../elisa/o/optimal_file_merging.elisa)
- Nim: [`nim/o/optimal_file_merging.nim`](../../../nim/o/optimal_file_merging.nim)
- Odin: [`odin/o/optimal_file_merging.odin`](../../../odin/o/optimal_file_merging.odin)
- Rust: [`rust/o/optimal_file_merging.rs`](../../../rust/o/optimal_file_merging.rs)
- V: [`v/o/optimal_file_merging.v`](../../../v/o/optimal_file_merging.v)
- Zig: [`zig/o/optimal_file_merging.zig`](../../../zig/o/optimal_file_merging.zig)
