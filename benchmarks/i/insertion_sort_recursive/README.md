# Recursive insertion sort

This benchmark recursively sorts each prefix, then inserts the prefix's last value into its sorted position. It is stable and has worst-case `O(n^2)` time and `O(n)` call-stack space. The workload caps input length at 256 so the recursive call depth remains bounded.

The pinned C source uses recursive prefix sorting. The C++ source with the same filename uses iterative insertion sort, so this benchmark selects the recursive C method and ports it to all nine target languages. It sorts signed 64-bit integers in ascending order and uses the shared `sort` ABI. Run `python3 benchmarks/verify_insertion_sort_recursive.py` to check exhaustive short arrays, signed boundaries, random inputs, and every workload length across all nine languages.

## Upstream references

- [C `insertion_sort_recursive.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/insertion_sort_recursive.c)
- [C++ `insertion_sort_recursive.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/insertion_sort_recursive.cpp)
