# Remove Boxes

This benchmark maximizes the score earned by removing contiguous runs of
equal-colored boxes, where a removed run of length `k` scores `k²`. The primary
uses a compressed-run interval dynamic program with a third state dimension
that carries same-colored boxes from outside the current interval.

## Contract

- The `i64_array_scalar` input is `[n, color_0, ..., color_(n-1)]`.
- `0 <= n <= 18`; every color is an integer from `0` through `7`.
- The frame contains exactly `n + 1` signed 64-bit words. The empty sequence
  `[0]` returns `0`.
- Valid input returns the maximum possible total score. Invalid or null input
  returns `-1`.
- The maximum possible score is `18² = 324`.

## Algorithm and references

The primary first compresses consecutive equal colors. Its state
`dp(left, right, carry)` records the best score for a group interval while
`carry` matching boxes are already attached to its leftmost group. It either
removes that combined group now or clears an intervening interval so the group
can merge with a later group of the same color. The state space is `O(n³)`;
trying later matching groups gives a worst-case `O(n⁴)` recurrence.

The independent oracle memoizes complete remaining color sequences and tries
every contiguous equal-color run removal directly. It does not use interval
states or a carried-group count.

The official source is [LeetCode 546, Remove Boxes](https://leetcode.com/problems/remove-boxes/).
The public algorithm-note revision is pinned to
[`9ad43c8952fa474f76597738a599774d081103fc`](https://github.com/wisdompeak/LeetCode/blob/9ad43c8952fa474f76597738a599774d081103fc/DFS/546.Remove-Boxes/Readme.md).
These sources supply algorithm ideas and discovery metadata only; no source
code, tests, examples, statement text, or explanatory prose is copied.

This differs from [`burstballoons`](../../b/burstballoons/README.md), whose
two-dimensional interval dynamic program chooses the last item in an interval.
Remove Boxes needs an additional carry dimension to represent equal-colored
items that may join after intervening runs are removed.

## Workload and inventory

[`workload.json`](workload.json) covers empty and singleton inputs, runs that
merge after removals, distinct colors, the maximum length, malformed frames,
and invalid colors. The generated direct-search comparison corpus is exhaustive
through length five and random through length nine; the length-18 fixture is a
single color run, so the independent oracle remains small there. The static
workload verifier checks fixture metadata and both references, while
`check_inventory.py` checks the package files and all ten ports.

| Language | Port |
|---|---|
| C | `c/r/remove_boxes.c` |
| C3 | `c3/r/remove_boxes.c3` |
| C++ | `cpp/r/remove_boxes.cpp` |
| Elisa | `elisa/r/remove_boxes.elisa` |
| Mojo | `mojo/r/remove_boxes.mojo` |
| Nim | `nim/r/remove_boxes.nim` |
| Odin | `odin/r/remove_boxes.odin` |
| Rust | `rust/r/remove_boxes.rs` |
| V | `v/r/remove_boxes.v` |
| Zig | `zig/r/remove_boxes.zig` |
