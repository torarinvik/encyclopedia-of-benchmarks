# Minimum Excluded Value (MEX)

This benchmark ports `mex_using_sort` from the pinned Rust source. MEX is the smallest nonnegative integer that does not occur in the input. The source copies the slice, sorts the copy in ascending order, starts a candidate at zero, and increments it only when a sorted value equals that candidate. Negative values and duplicates therefore do not affect the result, and the input remains unchanged. The same source file also provides a set-based implementation; this package measures the sorting variant.

The packed `i64_array_scalar` input is `[n, values...]`, where `n` is 0 through 100,000 and every value is a signed 32-bit integer. The packed length must be exactly `n + 1`. An empty value list is valid and returns 0. Invalid layouts or out-of-range values return -1. The result is at most `n`, so it fits the signed 64-bit ABI. Each port sorts a bounded local copy and scans it for the first missing candidate.

This contract measures the MEX value, not the first missing positive value or the missing element relative to an array position. The source accepts `i64`; the signed 32-bit value restriction is a shared benchmark bound and does not change MEX for accepted inputs.

The pinned source is [TheAlgorithms/Rust `src/general/mex.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/mex.rs).
