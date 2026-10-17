# Project Euler Problem 44: start-cursor pentagonal difference

## Contract

For an integer start cursor `k` from 1 through 2166, first advance to high pentagonal index `k + 1`. Scan high indices upward through 2167. For each high index, scan lower indices downward from `high - 1` to 1 and return the first difference `P(high) - P(low)` for which both the difference and sum are pentagonal, where `P(n) = n(3n - 1)/2`. The result is `5,482,660` for every supported start cursor. Inputs outside the supported range return `-1`.

This is the pinned JavaScript candidate's start-cursor traversal. It has a different input meaning and pair order from [`problem44`](../problem44/README.md), which takes an exclusive index limit and scans lower index first. This benchmark caps the source search at high index 2167: the source's canonical pair is reached for every supported cursor, while larger cursors are outside this bounded contract.

All arithmetic is exact signed 64-bit integer arithmetic. Pentagonal membership uses the equivalent integer criterion that `24x + 1` is a perfect square and its root plus one is divisible by six. The maximum tested sum is below 15 million, so the discriminant and the binary-search square checks remain within the signed 64-bit range. The loops retain the source's high-index ascending and low-index descending order.

## Workload

[`workload.json`](workload.json) covers the earliest and latest supported cursors, middle and near-end cursors, and both out-of-range boundaries. The scalar benchmark uses one sample without warmup because the nested scan cost depends on the start cursor.

## TheAlgorithms reference

The pinned JavaScript [`Problem044.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Project-Euler/Problem044.js) increments `k` before checking, then visits high pentagonal indices in ascending order and lower indices in descending order. Its `isPentagonal` function tests whether `(sqrt(24x + 1) + 1) / 6` is integral. This bounded port uses an exact integer-square test for the same predicate.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem44_start_cursor.c](../../../c/p/problem44_start_cursor.c) |
| C3 | [c3/p/problem44_start_cursor.c3](../../../c3/p/problem44_start_cursor.c3) |
| C++ | [cpp/p/problem44_start_cursor.cpp](../../../cpp/p/problem44_start_cursor.cpp) |
| Elisa | [elisa/p/problem44_start_cursor.elisa](../../../elisa/p/problem44_start_cursor.elisa) |
| Nim | [nim/p/problem44_start_cursor.nim](../../../nim/p/problem44_start_cursor.nim) |
| Odin | [odin/p/problem44_start_cursor.odin](../../../odin/p/problem44_start_cursor.odin) |
| Rust | [rust/p/problem44_start_cursor.rs](../../../rust/p/problem44_start_cursor.rs) |
| V | [v/p/problem44_start_cursor.v](../../../v/p/problem44_start_cursor.v) |
| Zig | [zig/p/problem44_start_cursor.zig](../../../zig/p/problem44_start_cursor.zig) |
