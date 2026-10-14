# Patience sort

Patience sort places each value on the leftmost pile whose top is greater than or equal to it, then merges the piles by repeatedly removing the least exposed value. The benchmark uses binary search to place values and a binary min-heap to merge pile tops, giving `O(n log n)` time and `O(n)` auxiliary storage. Its shared contract sorts signed 64-bit integers in ascending order, accepts lengths from 0 through 1024, and leaves the input buffer sorted in place.

The pinned C implementation scans piles and scans all exposed tops during merging; the Rust implementation uses binary search for pile placement but scans exposed pile tops during merging. Java and Python use heap-based merging. Their tie rules also differ: C starts a new pile on equality, while Rust, Java, and Python select an existing equal top. The shared contract standardizes the lower-bound rule used by Rust, Java, and Python. The Assembly source is a discovery reference only; all benchmark ports use portable language code and generic compiler targets.

Run `python3 benchmarks/verify_patience_sort.py` to check short-array order patterns, signed boundaries, deterministic random arrays, and every published workload length across all nine languages.

## Upstream references

- [C `patience_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/patience_sort.c)
- [Java `PatienceSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/PatienceSort.java)
- [Python `patience_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/patience_sort.py)
- [R `patience_sort.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/sorting_algorithms/patience_sort.r)
- [Rust `patience_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/patience_sort.rs)
