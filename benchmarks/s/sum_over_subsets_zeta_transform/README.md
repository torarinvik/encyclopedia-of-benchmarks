# Sum-over-subsets zeta transform

The subset zeta transform takes a function on bitmasks and computes, for every
mask `S`, the sum of the input function over all submasks `T` of `S`. It is the
subset-lattice form of a multidimensional prefix sum.

## Contract

- `i64_array_scalar` input is `[B, f(0), ..., f(2^B-1)]`, with `0 <= B <= 6`.
- Each function value is in `[0, 1,000,000]`; the array must contain exactly
  `1+2^B` words. Null, malformed, or out-of-range input returns `-1`.
- The transform updates each set bit from the corresponding mask with that bit
  cleared. Return the weighted checksum
  `sum((mask+1) * transformed[mask])` over all masks.
- A conservative checksum bound is `133120000000`; intermediate values fit
  signed 64-bit.
- The transform takes O(B·2^B) time and O(2^B) auxiliary space.

## Distinction from related packages

This benchmark returns the zeta transform of one supplied function. The local
[fast subset convolution](../../f/fast_subset_convolution/README.md) combines
two functions over disjoint submasks using ranked transforms and Möbius
inversion; it is a different operation even though it uses related transform
steps.

## Workload

`workload.json` covers zero dimensions, hand-checkable transforms, the maximum
dimension, all-zero data, and invalid frames and values. The primary oracle
uses the dimension-by-dimension transform; the independent oracle enumerates
every submask directly.

## Reference

- [OI Wiki: Prefix Sum and Difference, subset-sum DP](https://oi-wiki.org/basic/prefix-sum/).
