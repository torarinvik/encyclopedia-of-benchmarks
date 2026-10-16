# Merge sorted arrays

This package ports the pinned Python merge_sorted_arrays function. It validates both input arrays and merges them in nondecreasing order using two pointers; equal values are taken from the left array first.

## Contract

- Input is a signed i64 array laid out as [left_count, right_count, left_values..., right_values...].
- Each input array has 0 to 64 values, each in -1,000,000 through 1,000,000. Both arrays must be nondecreasing.
- Invalid packed input or an unsorted input array returns -1. Empty arrays, including two empty arrays, are valid.
- The ABI returns a deterministic scalar checksum of the merged output: sum((zero_based_merged_index + 1) * (merged_value + 1,000,001)). This adapts the source vector result to the scalar benchmark interface; all valid results fit signed i64.
- Stable ties are implemented by choosing the left value on equality, as in the source. Since values are plain integers, equal-source identity does not change the returned value sequence.

## Workload and oracle

[workload.json](workload.json) covers the source examples, empty arrays, ties, negatives, duplicates, maximum lengths, unsorted arrays, malformed packed lengths, and invalid value bounds. The independent oracle is [merge_sorted_oracle.py](../../merge_sorted_oracle.py).

Pinned source: [TheAlgorithms/Python merge_sorted.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/merge_sorted.py).

## Running and verifying

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm merge_sorted --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_scalar.py --algorithm merge_sorted

Verify a selected port with:

    python3 benchmarks/verify_i64_array_scalar.py --algorithm merge_sorted --languages rust

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/merge_sorted.c](../../../c/m/merge_sorted.c) |
| C3 | [c3/m/merge_sorted.c3](../../../c3/m/merge_sorted.c3) |
| C++ | [cpp/m/merge_sorted.cpp](../../../cpp/m/merge_sorted.cpp) |
| Elisa | [elisa/m/merge_sorted.elisa](../../../elisa/m/merge_sorted.elisa) |
| Nim | [nim/m/merge_sorted.nim](../../../nim/m/merge_sorted.nim) |
| Odin | [odin/m/merge_sorted.odin](../../../odin/m/merge_sorted.odin) |
| Rust | [rust/m/merge_sorted.rs](../../../rust/m/merge_sorted.rs) |
| V | [v/m/merge_sorted.v](../../../v/m/merge_sorted.v) |
| Zig | [zig/m/merge_sorted.zig](../../../zig/m/merge_sorted.zig) |
