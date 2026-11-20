# Maximum-sum rectangle no larger than K

Find the greatest sum of a nonempty axis-aligned contiguous rectangle whose
sum does not exceed a supplied ceiling. This is the constrained variant of the
two-dimensional maximum-subarray problem. It differs from
[`maximum_sum_contiguous_submatrix`](../maximum_sum_contiguous_submatrix/README.md),
which has no ceiling and uses Kadane's unconstrained scan, and from
[`submatrix`](../../s/submatrix/README.md), which extracts a requested region.

## Bounded scalar contract

The exported `max_sum_rectangle_no_larger_than_k` function uses
`i64_array_scalar`. Input is `[rows,columns,K,cells...]`, with row-major
cells, `1<=rows,columns<=8`, cell values in `[-16,16]`, and
`-1024<=K<=1024`. The frame must contain exactly `3+rows*columns` words.
The maximum valid length is 67 words; one trailing word is parseable, so the
maximum parseable length is 68.

The result is the maximum sum of any nonempty contiguous rectangle with sum
`<=K`. If no such rectangle exists, return `-1025`. Return `-1026` for a
null or malformed input. Every actual rectangle sum is in `[-1024,1024]`,
so both status values are outside the valid result range.

## Method

Choose the shorter matrix dimension for band boundaries. Extend each band and
accumulate its values along the longer dimension. For each compressed array,
scan prefix sums from left to right. If the current prefix is `p`, any earlier
prefix `q>=p-K` gives a nonempty subarray sum `p-q<=K`; the smallest such
`q` gives the largest qualifying sum ending here. Keep earlier prefixes in a
sorted fixed-capacity vector and locate the successor with lower-bound search.
This bounded implementation takes `O(s^2*l^2)` time in the worst case because
vector insertion shifts up to `l` entries, where `s=min(rows,columns)` and
`l=max(rows,columns)`; it uses `O(l)` auxiliary space.

The primary oracle follows band compression and prefix-successor queries.
The independent reference directly enumerates every rectangle and sums its
cells, without using prefixes or compressed bands. Fixtures include feasible
and infeasible ceilings, all-negative answers, duplicate prefixes, both band
orientations, and the full 8x8 boundary.

## Discovery, references, and rights

The public [LeetCode title](https://leetcode.com/problems/max-sum-of-rectangle-no-larger-than-k/)
was used only to discover the algorithm topic. No problem statement, examples,
tests, submissions, editorial, or site code were read or reused.

The one-dimensional constrained subproblem is explicitly posed in Jeff
Erickson's [Algorithms, chapter 3, exercise 4(d)](https://jeffe.cs.illinois.edu/teaching/algorithms/book/Algorithms-JeffE.pdf):
find a contiguous subarray with largest sum at most a bound. The two-dimensional
reduction by fixing row bands and applying a one-dimensional maximum-subarray
algorithm is described in ETH Zürich's [VerifyThis 2017 Challenge 2](https://formal.kastel.kit.edu/ulbrich/verifythis2017/challenge2.pdf).
Combining the band reduction with the prefix-successor condition yields the
bounded clean-room method documented above. See [RIGHTS.md](RIGHTS.md).

## Workload and references

- Workload: [`workload.json`](workload.json)
- Band-compression primary oracle: [`max_sum_rectangle_no_larger_than_k_oracle.py`](../../max_sum_rectangle_no_larger_than_k_oracle.py)
- Direct-cell independent oracle: [`max_sum_rectangle_no_larger_than_k_independent_oracle.py`](../../max_sum_rectangle_no_larger_than_k_independent_oracle.py)
- Static inventory: [`INVENTORY.md`](INVENTORY.md)

The ten source ports are listed in [`INVENTORY.md`](INVENTORY.md).
