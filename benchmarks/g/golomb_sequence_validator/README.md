# Golomb sequence validator

The Java candidate named `CountFriendsPairing` does not count friend pairings. It builds a Golomb sequence prefix and checks the supplied values against that prefix. This benchmark preserves that validator behavior as a distinct algorithm.

## Contract

- The packed input is `[n, value_0, ..., value_(n-2)]`, where `n` is from 1 through 1,024. The input length must equal `n`.
- The `n - 1` supplied values must fit signed 32-bit integers.
- Build `dp[0] = 1` and, for each `i` from 1 through `n - 1`, compute `dp[i] = 1 + dp[i - dp[dp[i - 1]]]`. The zero-initialized `dp[1]` slot makes the first iteration produce `dp[1] = 1`, as in the Java implementation.
- Return `1` when the supplied values exactly match `dp[1..n-1]`, otherwise return `0`. Since `n = 1` has an empty prefix, `[1]` returns `1`.
- Return `-1` for an invalid length, out-of-range `n`, or a supplied value outside signed 32-bit range.

All ports use the `i64_array_scalar` ABI and a fixed 1,024-element table. The recurrence runs in O(n) time and uses O(n) stack storage.

## Workload

[`workload.json`](workload.json) covers the empty prefix, matching and mismatching prefixes, malformed lengths, and invalid bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/golomb_sequence_validator.c`](../../../c/g/golomb_sequence_validator.c) |
| C3 | [`c3/g/golomb_sequence_validator.c3`](../../../c3/g/golomb_sequence_validator.c3) |
| C++ | [`cpp/g/golomb_sequence_validator.cpp`](../../../cpp/g/golomb_sequence_validator.cpp) |
| Elisa | [`elisa/g/golomb_sequence_validator.elisa`](../../../elisa/g/golomb_sequence_validator.elisa) |
| Nim | [`nim/g/golomb_sequence_validator.nim`](../../../nim/g/golomb_sequence_validator.nim) |
| Odin | [`odin/g/golomb_sequence_validator.odin`](../../../odin/g/golomb_sequence_validator.odin) |
| Rust | [`rust/g/golomb_sequence_validator.rs`](../../../rust/g/golomb_sequence_validator.rs) |
| V | [`v/g/golomb_sequence_validator.v`](../../../v/g/golomb_sequence_validator.v) |
| Zig | [`zig/g/golomb_sequence_validator.zig`](../../../zig/g/golomb_sequence_validator.zig) |

## TheAlgorithms reference

- [Java `CountFriendsPairing.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/CountFriendsPairing.java)
