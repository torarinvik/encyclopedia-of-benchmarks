# Bingo sort

Bingo sort repeatedly finds the smallest value remaining, moves all copies to the next sorted prefix, then continues with the next value. The nine ports sort signed 64-bit values in place up to length 1024. Each pass scans the remaining suffix, so worst-case time is `O(n^2)` and auxiliary storage is `O(1)`.

The pinned Rust source walks every integer from the minimum to the maximum and scans the array for each value. The shared contract tracks the next value actually present instead, preserving the grouping strategy while avoiding enormous empty value ranges and signed overflow.

Run `python3 benchmarks/verify_bingo_sort.py` to check duplicate patterns, signed 64-bit boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream reference

- [Rust `bingo_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/bingo_sort.rs)
