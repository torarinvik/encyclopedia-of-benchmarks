# Adaptive merge sort

Adaptive merge sort uses top-down recursive splitting and stable merging, then skips a merge when the two recursively sorted halves already meet in order. This gives linear work on already sorted input while keeping the usual `O(n log n)` worst-case time, `O(n)` auxiliary storage, and `O(log n)` recursion depth. The nine ports use one reusable fixed-size scratch buffer and sort signed 64-bit values in place up to length 1,024.

The workload contains sorted arrays (`values[index] = index`) at lengths 0, 16, 64, 256, and 1,024 to exercise the adaptive fast path. The benchmark uses the shared sort ABI and checks the full sorted output after each timed call. The ports retain the early-exit comparison after both halves are recursively sorted.

The pinned Python implementation has this early-exit optimization. The pinned Java class named `AdaptiveMergeSort` performs the same top-down recursive split and stable merge without the early exit; it is included as a conventional implementation of the same sort contract. This benchmark remains distinct from `merge_sorter`, which always merges each recursively sorted pair, and from the bottom-up `merge_sort` and `merge_sort_nr` benchmarks.

## Upstream references

- [Java `AdaptiveMergeSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/AdaptiveMergeSort.java)
- [Python `adaptive_merge_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/adaptive_merge_sort.py)
