# Remove Duplicates From Sorted Array

This benchmark compacts a nondecreasing integer array so that each value occurs once, preserving the original order. It ports the C LeetCode 26 write-index algorithm. The upstream function modifies its input array in place; this shared ABI emits the same compacted prefix to a separate output buffer so every language has an observable result.

## Contract

- Input is an array of zero to 4,096 signed 32-bit integers in ascending order.
- Unsorted input or values outside the signed 32-bit range return `-1`.
- The output is the unique prefix, encoded as little-endian signed 32-bit values. The return value is the prefix length. Insufficient output capacity returns `-2`.
- The implementation uses a read cursor and a write count, storing each value only when it differs from its predecessor. Input is not modified by the shared ABI.

The numeric C LeetCode source stem `26` is cataloged under the alphabetic algorithm name `remove_duplicates_from_sorted_array`.

Run `python3 benchmarks/verify_remove_duplicates_from_sorted_array.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive sorted arrays, seeded random inputs, signed boundaries, malformed arrays, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/r/remove_duplicates_from_sorted_array.c`](../../../c/r/remove_duplicates_from_sorted_array.c), [`c3/r/remove_duplicates_from_sorted_array.c3`](../../../c3/r/remove_duplicates_from_sorted_array.c3), [`cpp/r/remove_duplicates_from_sorted_array.cpp`](../../../cpp/r/remove_duplicates_from_sorted_array.cpp), [`elisa/r/remove_duplicates_from_sorted_array.elisa`](../../../elisa/r/remove_duplicates_from_sorted_array.elisa), [`nim/r/remove_duplicates_from_sorted_array.nim`](../../../nim/r/remove_duplicates_from_sorted_array.nim), [`odin/r/remove_duplicates_from_sorted_array.odin`](../../../odin/r/remove_duplicates_from_sorted_array.odin), [`rust/r/remove_duplicates_from_sorted_array.rs`](../../../rust/r/remove_duplicates_from_sorted_array.rs), [`v/r/remove_duplicates_from_sorted_array.v`](../../../v/r/remove_duplicates_from_sorted_array.v), and [`zig/r/remove_duplicates_from_sorted_array.zig`](../../../zig/r/remove_duplicates_from_sorted_array.zig). They use generic compiler targets without architecture-specific instructions.

## Upstream reference

- [C LeetCode 26](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/26.c)
