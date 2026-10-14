# Non-recursive merge sort

Non-recursive merge sort starts with runs of one value and repeatedly merges adjacent runs until the entire array is sorted. The nine ports use bottom-up passes, a fixed scratch buffer, signed 64-bit values, and stable left-first handling when values compare equal. The contract accepts arrays up to 1024 values; the algorithm uses `O(n log n)` time and `O(n)` auxiliary storage.

The pinned C source describes the same bottom-up strategy but allocates temporary storage for only 50 values and includes interactive input and output. These ports expose a benchmark function, use a 1024-value bound, and keep I/O outside the timed call. The existing recursive `merge_sort` remains a separate benchmark so the iterative and recursive strategies can be compared.

Run `python3 benchmarks/verify_merge_sort_nr.py` to check short-array order patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream reference

- [C `merge_sort_nr.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/merge_sort_nr.c)
