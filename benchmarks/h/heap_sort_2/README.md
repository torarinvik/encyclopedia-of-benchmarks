# Heap sort with top-down heap construction

This Heap sort variant builds its max heap by inserting each value into the prefix and sifting it upward. It then swaps the maximum to the end and sifts the replacement root downward. The nine ports sort signed 64-bit values in place up to length 1024; time is `O(n log n)` and auxiliary storage is `O(1)`.

The pinned C source uses the same repeated sift-up construction and sift-down extraction, but limits inputs to `int8_t` values and an 8-bit length. Its randomized demonstration also includes console I/O. The benchmark widens the value domain, bounds the length at 1024, and keeps I/O outside the timed call. This heap-construction strategy is separate from the existing `heap_sort` benchmark's bottom-up construction.

Run `python3 benchmarks/verify_heap_sort_2.py` to check short-array order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream reference

- [C `heap_sort_2.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/heap_sort_2.c)
