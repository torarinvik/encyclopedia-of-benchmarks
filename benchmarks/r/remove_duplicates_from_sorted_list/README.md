# Remove Duplicates from Sorted List

This benchmark ports C LeetCode 83. It represents the sorted list as an indexed node chain and removes each later node whose value equals its predecessor, keeping the first node in each equal-value run.

## Contract

- Input contains zero to 1,024 sorted signed 32-bit node values in non-decreasing order.
- An invalid length, value, or ordering returns `-1`.
- The result is the number of retained nodes. Their values are serialized in list order as little-endian signed 32-bit integers.
- Insufficient output capacity returns `-2` before any output bytes are written.
- Each implementation builds an index-based forward link chain and applies the source's current/next-node unlinking loop.

The numeric upstream filename `83.c` is cataloged under the alphabetic algorithm name `remove_duplicates_from_sorted_list`. Input data is immutable to the caller; the link array is local to each call.

Run `python3 benchmarks/verify_remove_duplicates_from_sorted_list.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive sorted short lists, seeded random lists, signed 32-bit boundaries, maximum-size lists, invalid ordering and values, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/r/remove_duplicates_from_sorted_list.c`](../../../c/r/remove_duplicates_from_sorted_list.c), [`c3/r/remove_duplicates_from_sorted_list.c3`](../../../c3/r/remove_duplicates_from_sorted_list.c3), [`cpp/r/remove_duplicates_from_sorted_list.cpp`](../../../cpp/r/remove_duplicates_from_sorted_list.cpp), [`elisa/r/remove_duplicates_from_sorted_list.elisa`](../../../elisa/r/remove_duplicates_from_sorted_list.elisa), [`nim/r/remove_duplicates_from_sorted_list.nim`](../../../nim/r/remove_duplicates_from_sorted_list.nim), [`odin/r/remove_duplicates_from_sorted_list.odin`](../../../odin/r/remove_duplicates_from_sorted_list.odin), [`rust/r/remove_duplicates_from_sorted_list.rs`](../../../rust/r/remove_duplicates_from_sorted_list.rs), [`v/r/remove_duplicates_from_sorted_list.v`](../../../v/r/remove_duplicates_from_sorted_list.v), and [`zig/r/remove_duplicates_from_sorted_list.zig`](../../../zig/r/remove_duplicates_from_sorted_list.zig). They use portable scalar integer operations without architecture-specific instructions.

## Upstream reference

- [TheAlgorithms/C LeetCode 83](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/83.c)
