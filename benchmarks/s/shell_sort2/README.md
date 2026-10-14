# Shell sort with the Ciura gap sequence

This Shell sort variant performs gapped insertion passes using the fixed sequence `701, 301, 132, 57, 23, 10, 4, 1`. It sorts signed 64-bit integers in place in ascending order. The final gap of one completes ordinary insertion sort. The workload covers lengths 0 through 1024.

The pinned C and C++ `shell_sort2` files use this same gap sequence, unlike the existing `shell_sort` benchmark, which halves the current input length each pass. Their original comparison subtracts the two values; the portable ports use a relational comparison so signed 64-bit boundary values do not overflow.

Run `python3 benchmarks/verify_shell_sort2.py` to check short-array patterns, signed boundaries, deterministic random arrays, and each published workload length in all nine languages.

## Upstream references

- [C `shell_sort2.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/shell_sort2.c)
- [C++ `shell_sort2.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/shell_sort2.cpp)
- [Additional C++ `shell_sort2.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/shell_sort2.cpp)
