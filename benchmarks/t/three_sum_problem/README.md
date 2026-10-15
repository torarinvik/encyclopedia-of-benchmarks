# Three Sum Problem

Return every unique value triplet whose sum equals a supplied target, using the two-pointer variant of the pinned Java source.

## Contract

- The `i64_array_bytes_output` ABI receives packed input `[target, n, values...]`: `target` is a signed 32-bit integer, `n` is the number of values, followed by exactly `n` values.
- `n` is from 0 through 257. Each value is in `[-100,000, 100,000]`. The target spans the signed 32-bit range. Arrays shorter than three values return no triplets.
- Results are unique by triplet values, with each triplet formed from three distinct input positions. Values inside each triplet are ascending, and all triplets are returned in lexicographic order. The input is left unchanged.
- Each triplet is encoded as three signed 32-bit little-endian values with no separators. The function returns the triplet count. Invalid packed input returns `-1`; insufficient output capacity returns `-2` without writing.
- The maximum possible output allocation bound is `C(n,2) * 12` bytes. At `n=257`, this is 394,752 bytes, below the shared output limit.

## Source semantics and normalization

The pinned [Java `ThreeSumProblem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/ThreeSumProblem.java) provides brute-force, two-pointer, and hash-map methods for an arbitrary target. This benchmark uses the two-pointer method's value-set behavior. Its source sorts the caller's array and deduplicates results after scanning; this ABI sorts a private copy and emits the unique triples lexicographically. The brute-force method retains first-seen result order, while the hash-map method uses an unordered set, so their outer ordering is normalized here.

This package extends the zero-target [`3sum`](../../0-9/3sum/README.md) contract with a target argument. Target zero has the same triplet set as that benchmark; nonzero targets are additional inputs.

## Workload

[`workload.json`](workload.json) covers zero and nonzero targets, duplicate values, no matches, short arrays, and malformed packed input. The runner uses `i64_array_bytes_output`; its oracle integration is maintained separately.
