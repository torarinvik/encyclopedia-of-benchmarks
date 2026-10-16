# Triplet Sum (Permutation Search)

This benchmark preserves the pinned Python `triplet_sum1` implementation. It checks ordered triples of distinct input positions in permutation order and returns the first matching triple with its values sorted in nondecreasing order. The input bound is intentionally small because this search takes O(n³) time.

## Contract

- Input is `[target, values...]`, with 0 through 10 values, target in `[-3,000,000, 3,000,000]`, and values in `[-1,000,000, 1,000,000]`.
- A match returns its three values sorted ascending. If no match exists, the source returns `(0, 0, 0)`. This sentinel is indistinguishable from an actual zero-valued triplet, matching the source API.
- Output is always three signed 64-bit integers in little-endian order; a valid call returns 3. Invalid input returns `-1`; insufficient capacity returns `-2` without writing.
- Inputs are read-only in the shared ABI.

The source is [TheAlgorithms/Python `maths/triplet_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/triplet_sum.py). The benchmark keeps `triplet_sum1` separate from its optimized sibling because the two algorithms can choose different valid triplets.

`workload.json` includes input-order tie cases, duplicate values, signed boundaries, no-match behavior, and invalid bounds. The verifier checks against an independent positional-permutation oracle and covers all arrays of up to five values over a small signed domain.
