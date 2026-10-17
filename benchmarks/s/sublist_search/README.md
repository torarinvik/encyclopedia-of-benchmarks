# Sublist search

Search for an entire integer pattern as a contiguous run in an integer main list. This package adapts the two matching pinned C++ implementations of the same naive linked-list scan.

## Contract

The i64_array_scalar input layout is [main_count, pattern_count, main_values..., pattern_values...]. Each count is in 0..64, every value is in 0..2,147,483,647, and the input contains exactly 2 + main_count + pattern_count signed 64-bit values. The value bound keeps the source's conversion through int lossless.

The result is 1 when the full pattern occurs contiguously in the main list and 0 otherwise. The source returns false when either linked-list head is null; therefore an empty main list and an empty pattern both return 0. Invalid counts, values, or framing return -1.

The implementation scans candidate main-list starts from left to right, compares each pattern value in sequence, and restarts the pattern at its head after a mismatch. The bounded lists require at most 4,096 comparisons. Each call builds its logical lists from the packed input and keeps no state between calls.

## Workload and oracle

[workload.json](workload.json) covers the pinned source example, first and last positions, full-list and single-value matches, repeated prefixes, duplicates, order, empty lists, the maximum input, a long repeated-prefix miss, the 32-bit value boundary, and malformed frames. The independent [oracle](../../sublist_search_oracle.py) checks each contiguous candidate slice.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus sublist_search.cpp at fdcc29b0ac2848e9d1a8d926e171cc5b39f97759](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/sublist_search.cpp)
- [TheAlgorithms/C-Plus-Plus-1 sublist_search.cpp at 0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/search/sublist_search.cpp)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/sublist_search.c](../../../c/s/sublist_search.c) |
| C3 | [c3/s/sublist_search.c3](../../../c3/s/sublist_search.c3) |
| C++ | [cpp/s/sublist_search.cpp](../../../cpp/s/sublist_search.cpp) |
| Elisa | [elisa/s/sublist_search.elisa](../../../elisa/s/sublist_search.elisa) |
| Nim | [nim/s/sublist_search.nim](../../../nim/s/sublist_search.nim) |
| Odin | [odin/s/sublist_search.odin](../../../odin/s/sublist_search.odin) |
| Rust | [rust/s/sublist_search.rs](../../../rust/s/sublist_search.rs) |
| V | [v/s/sublist_search.v](../../../v/s/sublist_search.v) |
| Zig | [zig/s/sublist_search.zig](../../../zig/s/sublist_search.zig) |
