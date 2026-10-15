# Merge Two Sorted Lists

This benchmark merges two ascending singly linked list value sequences into one ascending sequence. The pinned C LeetCode 21 file contains both iterative and recursive definitions of the same function name; the benchmark selects the iterative linear two-pointer merge. JavaScript uses the same merge method, and Dart implements the same linked-list merge. Python's helper rebuilds a sorted list from the two inputs, so its time complexity differs, but its output semantics match on the shared sorted-input domain.

## Contract

- Input is `[count_a, count_b, values_a..., values_b...]`, with both counts nonnegative and their sum from 0 through 1,024.
- Each input list must be ascending and contain signed 32-bit values. Malformed lengths, unsorted lists, or out-of-range values return `-1`.
- The output is the merged ascending sequence encoded as little-endian signed 32-bit values. The return value is the merged element count. Insufficient output capacity returns `-2`.
- The ports use cursor-based merging over the packed value arrays. This preserves the linear merge work while giving every language the same bounded input and output representation.

The numeric C LeetCode source stem `21` is cataloged under the algorithm name `merge_two_sorted_lists`. Candidates with other source names are reviewed as aliases because they return the same merged value sequence.

Run `python3 benchmarks/verify_merge_two_sorted_lists.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short sorted-list pairs, seeded random pairs, boundary values, malformed cases, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/m/merge_two_sorted_lists.c`](../../../c/m/merge_two_sorted_lists.c), [`c3/m/merge_two_sorted_lists.c3`](../../../c3/m/merge_two_sorted_lists.c3), [`cpp/m/merge_two_sorted_lists.cpp`](../../../cpp/m/merge_two_sorted_lists.cpp), [`elisa/m/merge_two_sorted_lists.elisa`](../../../elisa/m/merge_two_sorted_lists.elisa), [`nim/m/merge_two_sorted_lists.nim`](../../../nim/m/merge_two_sorted_lists.nim), [`odin/m/merge_two_sorted_lists.odin`](../../../odin/m/merge_two_sorted_lists.odin), [`rust/m/merge_two_sorted_lists.rs`](../../../rust/m/merge_two_sorted_lists.rs), [`v/m/merge_two_sorted_lists.v`](../../../v/m/merge_two_sorted_lists.v), and [`zig/m/merge_two_sorted_lists.zig`](../../../zig/m/merge_two_sorted_lists.zig). They use generic compiler targets without architecture-specific instructions.

## Upstream references

- [C LeetCode 21](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/21.c)
- [Dart `merge_sorted_list.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/linked_list/merge_sorted_list.dart)
- [Python `merge_two_lists.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/merge_two_lists.py)
- [JavaScript `MergeTwoSortedLinkedLists.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/MergeTwoSortedLinkedLists.js)
