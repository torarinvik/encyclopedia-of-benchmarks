# Recursive bubble sort

Recursive bubble sort runs one adjacent-swap pass, then recursively sorts the prefix that excludes the last value placed by the pass. It stops early when a pass makes no swaps. The nine ports sort signed 64-bit values in place, preserve equal-value order through adjacent swaps, and cap inputs at 256 values to bound recursion depth. Worst-case time is `O(n^2)` and auxiliary call-stack space is `O(n)`.

The pinned Java source uses this in-place recursion. The Python source uses the same swap pass and early exit but recursively sorts a sliced prefix into a new list; the shared benchmark follows Java's in-place behavior so every port uses the same mutable-array contract. The C++ and Fortran recursive bubble-sort sources omit only the early-exit check and map to this same algorithm.

Run `python3 benchmarks/verify_bubble_sort_recursive.py` to check short-array order and duplicate patterns, signed boundaries, deterministic random arrays, and every published workload length in all nine languages.

## Upstream references

- [Java `BubbleSortRecursive.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/BubbleSortRecursive.java)
- [Python `bubble_sort_recursive.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/bubble_sort_recursive.py)
