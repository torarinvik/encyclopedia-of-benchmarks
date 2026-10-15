# Count nice subarrays

Counts contiguous subarrays that contain exactly `k` odd values. This package follows the pinned Java implementation's memoized sliding window. It counts negative odd values as odd, matching the source's `(value & 1) == 1` check.

## Contract

- Uses `i64_array_scalar` with packed input `[n, k, values...]`.
- `n` is from 0 through 4,096, `k` is from 1 through 4,096, and every array value is a signed 32-bit integer. `k > n` is valid and returns 0; an empty array also returns 0.
- Returns the number of contiguous subarrays containing exactly `k` odd values. The count is at most `n(n+1)/2`, or 8,390,656 at the maximum length, so it fits the pinned source's signed 32-bit result.
- Malformed packed inputs return `-1`. The benchmark excludes `k=0`: in the pinned implementation, its scan of leading even values can read beyond the array when `k` is zero.

## Source

This package follows [TheAlgorithms Java `CountNiceSubarrays.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/CountNiceSubarrays.java). For each right endpoint, the source updates the odd count, advances the left edge by the memoized even prefix when the count exceeds `k`, and adds the number of valid starts when the count equals `k`.
