# Smoothsort

This benchmark follows the pinned Java in-place Smoothsort implementation for
signed integer arrays. It sorts the values in ascending numeric order and
returns a weighted checksum of that sorted sequence.

## Contract

The `i64_array_scalar` input is `[n, values...]`. The length `n` is in
0..512, the input contains exactly `n` values, and each value is in
`-1,000,000..1,000,000`. The benchmark applies Smoothsort in place to a local
mutable copy of those values. The returned result is
`sum((i + 1) * (sorted_value[i] + 1,000,001))` for zero-based `i`. This keeps
all valid results nonnegative and
within signed 64-bit; an empty array returns zero. Malformed framing or
out-of-range fields return `-1`.

The maximum valid input length is 513 integers; the maximum parseable length
is 514. The pinned source returns arrays shorter than two elements unchanged.
It compares elements through `Comparable.compareTo` using a strict less-than
predicate. Duplicate integers therefore sort correctly, with no promise about
stability; stability is not observable for integer values. The bounded length
also stays far below the source's largest Leonardo-number index.

## Pinned sources

- TheAlgorithms/Java [`SmoothSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SmoothSort.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`
- Its comparison helper [`SortUtils.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SortUtils.java), at the same commit

## Workload

The workload is [`workload.json`](workload.json); the independent
ascending-sort oracle is [`benchmarks/smooth_sort_oracle.py`](../../smooth_sort_oracle.py).
