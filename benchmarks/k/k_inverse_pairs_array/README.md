# K inverse pairs array

Count permutations of `1..n` having exactly `k` inversions, modulo 1,000,000,007. This measures the Mahonian distribution, not the inversion count of a supplied array.

## Contract

- The scalar input is exactly `[n,k]`, with `0<=n<=128` and `0<=k<=512`.
- Return `-1` for a malformed frame or out-of-range parameter. For valid parameters with `k>n(n-1)/2`, return `0`.
- Otherwise return the number of permutations of `1..n` with exactly `k` inversion pairs, modulo 1,000,000,007. The empty permutation has one arrangement, so `[0,0]` returns `1`.
- The exported symbol is `k_inverse_pairs_array`; the ABI is `i64_array_scalar`. The maximum valid input length is 2 signed 64-bit values. A bounded trailing-word frame of length 3 is parseable and malformed.

## Method and distinctness

Insert the largest value into a permutation of the previous size. Its insertion position adds any inversion count from zero through `size-1`, so the coefficient polynomial is multiplied by `1+q+...+q^(size-1)`. The primary implementation computes each new coefficient with a sliding window in `O(nk)` time and `O(k)` storage. The independent reference expands each bounded factor directly, with a separate factorial enumeration helper for small input sizes.

`count_inversions` counts the inversions in a supplied sequence, and `static_range_inversions_query` counts inversions inside supplied subranges. Neither counts how many permutations have a chosen inversion total. Inversion-sequence generation and tree-poset inversion optimization packages also expose different operations.

## Discovery, references, and rights

The LeetCode title catalog supplied discovery only: [K Inverse Pairs Array](https://leetcode.com/problems/k-inverse-pairs-array/). No problem statement, example, test, submission, editorial, or site code is used. The mathematical description is independently checked against Knuth's *The Art of Computer Programming*, volume 3, section 5.1.1, and the [Mahonian numbers entry OEIS A008302](https://oeis.org/A008302), which identifies the coefficients of `product(i=0..n-1, 1+q+...+q^i)`. The implementations, fixtures, and references here are independently written; see [`RIGHTS.md`](RIGHTS.md).

## Workload and references

- Workload: [`workload.json`](workload.json)
- Sliding-window primary oracle: [`k_inverse_pairs_array_oracle.py`](../../k_inverse_pairs_array_oracle.py)
- Direct truncated-product reference: [`k_inverse_pairs_array_independent_oracle.py`](../../k_inverse_pairs_array_independent_oracle.py)
- Static source inventory: [`check_inventory.py`](check_inventory.py)

## Ports

The ten implementations are listed in [`INVENTORY.md`](INVENTORY.md), under the repository's `c/`, `c3/`, `cpp/`, `elisa/`, `mojo/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/` source trees.
