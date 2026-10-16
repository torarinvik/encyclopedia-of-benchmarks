# Recursive top-down merge sort

Top-down merge sort recursively divides the input range into halves, sorts each half, and merges the sorted halves. The nine ports use one reusable scratch buffer, merge equal values from the left to preserve stability, and sort signed 64-bit values in place up to length 1024. Time complexity is `O(n log n)`, auxiliary storage is `O(n)`, and recursion depth is `O(log n)`.

The pinned C-Sharp `MergeSorter` allocates two new arrays at each split and merges them back. The shared ABI uses a single fixed scratch array allocated once per sort call, keeping the recursive top-down strategy while bounding stack and allocation use. This remains separate from the bottom-up `merge_sort` and `merge_sort_nr` benchmarks. The pinned Java `ConcurrentMergeSort` source uses concurrent tasks above a threshold, but has the same stable sorted-output semantics; candidate `concurrent_merge_sort` maps here. This benchmark does not include Java-specific thread scheduling or CPU-count-dependent task creation.

Run `python3 benchmarks/verify_merge_sorter.py` to check short-array order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream reference

- [C-Sharp `MergeSorter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/MergeSorter.cs)
