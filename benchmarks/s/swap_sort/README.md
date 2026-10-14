# Swap sort

This benchmark measures the minimum number of pairwise swaps needed to put an array in ascending order. It follows the cycle-decomposition method in the pinned C++ `swap_sort.cpp` source and the intended minimum-swap behavior of the JavaScript and TypeScript files. Inputs contain distinct signed 64-bit values and at most 256 elements; an empty array needs zero swaps, while duplicate values and longer arrays return `-1` because duplicate-value assignments can have multiple minimum-swap solutions.

The benchmark sorts `(value, original_index)` pairs with a portable binary heap, then counts permutation cycles. This gives `O(n log n)` time and `O(n)` auxiliary storage across all nine languages. The Java `SwapSort` class with the same filename sorts the input array in place and returns that array rather than counting swaps. The JavaScript and TypeScript versions use default language sorting and map values directly, so their behavior differs for multi-digit numbers and duplicates; the shared contract uses numeric ordering and rejects duplicates explicitly.

Run `python3 benchmarks/verify_swap_sort.py` to compare exhaustive small permutations, random distinct arrays, signed boundaries, invalid inputs, and every published workload case against an independent cycle-count oracle in all nine languages.

## Upstream references

- [C++ `swap_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/swap_sort.cpp)
- [Java `SwapSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SwapSort.java)
- [JavaScript `SwapSort.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/SwapSort.js)
- [TypeScript `swap_sort.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/sorts/swap_sort.ts)
