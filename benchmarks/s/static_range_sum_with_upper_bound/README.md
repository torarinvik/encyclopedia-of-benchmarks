# Static range counts and sums under a threshold

This draft builds a wavelet matrix augmented with prefix sums of values in
each zero partition. Each query returns the count and sum of values no greater
than its threshold in a half-open index range. The existing
[`wavelet_matrix`](../../w/wavelet_matrix/README.md) provides count queries but
does not expose thresholded value sums.

The proposed `i64_array_bytes_output` input is `[n,q,values[n],(l,r,x)[q]]`.
It accepts `1 <= n,q <= 64`, values and thresholds in `0..1,000,000,000`, and
`0 <= l <= r <= n`. Each answer is two little-endian signed i64 words: count,
then sum. Invalid or null input returns `-1`; null or insufficient output
returns `-2` without writes. Maximum valid input length is 258 words and
maximum output is 1024 bytes. The 30-bit matrix uses O(30n) build time and
space and O(30) time per query.

The [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/static_range_sum_with_upper_bound/task.md)
is used for the operation idea; the source repository declares Apache-2.0.
The contract and implementation are independently written, without copying
the task's prose, code, or fixtures.

Status: all ten language drafts, a direct-scan reference, workload, and
byte-output runner/verifier registration are present. Verifier source includes
boundary, maximum-size, oversized-input, and buffer cases; these drafts and
checks have not been compiled or run.
