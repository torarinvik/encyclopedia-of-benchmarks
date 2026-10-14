# Slow sort

Slow sort recursively sorts the two halves, swaps the midpoint and last values when they are out of order, then recursively sorts the prefix ending just before the last element. It sorts signed 64-bit integers in place through the shared `sort` ABI. The workload caps the input at 16 values because the recursive work grows very quickly.

The pinned Java implementation calls the inclusive range helper with `length - 1`. The pinned C++ helper also uses inclusive bounds, but its sample `main` passes `size`, which addresses one value beyond the array; the benchmark follows the Java call convention and always uses the final valid index. See [the verifier](../../verify_slow_sort.py) for exhaustive short-array patterns, signed boundaries, random inputs, and workload checks across all nine languages.

## Upstream references

- [C++ `slow_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/slow_sort.cpp)
- [Java `SlowSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SlowSort.java)
