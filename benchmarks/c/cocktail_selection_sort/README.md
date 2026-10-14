# Cocktail selection sort

Cocktail selection sort scans the active range to find its smallest and largest values, places them at the two ends, then shrinks the range from both sides. The nine ports sort signed 64-bit values in place up to length 1024. Each pass uses one linear scan; total time is `O(n^2)` with `O(1)` auxiliary storage.

The two pinned C++ copies contain the same interactive demo and implement both iterative and recursive entry points. Their endpoint swaps can misplace values when the maximum begins at the low endpoint and the minimum lies elsewhere: after moving the minimum, the original maximum index is stale. The benchmark uses the iterative two-ended selection strategy and updates that index after the first swap. All ports were checked against duplicate-heavy and boundary cases.

Run `python3 benchmarks/verify_cocktail_selection_sort.py` to check short-array order patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream references

- [C++ `cocktail_selection_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/cocktail_selection_sort.cpp)
- [Additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/cocktail_selection_sort.cpp)
