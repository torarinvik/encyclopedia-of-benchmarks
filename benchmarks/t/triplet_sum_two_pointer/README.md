# Triplet Sum (Sort and Two Pointers)

This benchmark preserves the pinned Python `triplet_sum2` implementation. It sorts a private copy, fixes each possible first position, and advances two pointers until it finds the first matching triplet. It runs in O(n²) search time after sorting.

## Contract

- Input is `[target, values...]`, with 0 through 1,024 values, target in `[-3,000,000, 3,000,000]`, and values in `[-1,000,000, 1,000,000]`.
- A match returns the first nondecreasing triplet found by the sorted two-pointer traversal. If no match exists, the source returns `(0, 0, 0)`, which is also the encoding of an actual zero-valued triplet.
- Output is always three signed 64-bit integers in little-endian order; a valid call returns 3. Invalid input returns `-1`; insufficient capacity returns `-2` without writing.
- The shared ABI keeps input read-only, so each port sorts a private copy. The source mutates its input list while sorting.

The source is [TheAlgorithms/Python `maths/triplet_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/triplet_sum.py). A portable heapsort keeps the local implementation independent of platform-specific instruction sets and standard-library sort choices.

`workload.json` covers alternative valid matches, duplicates, no-match behavior, invalid bounds, and arrays at the 1,024-value limit. The verifier compares results with an independent implementation of the pinned traversal and checks small arrays exhaustively.
