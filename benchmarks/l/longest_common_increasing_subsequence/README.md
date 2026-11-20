# Longest common increasing subsequence length

Return the length of a longest subsequence shared by two integer arrays whose
values increase strictly. This combines the order constraint from
[`longest_increasing_subsequence`](../longest_increasing_subsequence/README.md)
with the shared-order constraint from
[`longest_common_subsequence`](../longest_common_subsequence/README.md); the
answer is not an LIS of only one input or an arbitrary LCS.

## Contract

The `i64_array_scalar` input is
`[n,m,A_0,...,A_(n-1),B_0,...,B_(m-1)]`, with `0<=n,m<=32` and all values in
`[-16,16]`. The exact valid length is `2+n+m`; one additional word is
parseable and rejected. Empty arrays are allowed. Return an integer from
`0..min(n,m)`, or `-1` for a null, malformed, or out-of-range frame.

The primary ports use the one-row dynamic program. While processing each `A`
value, a scan of `B` tracks the best LCIS length ending at a strictly smaller
value; equal values extend from that running best. The independent reference
forms a DAG of equal-valued position pairs and computes its longest path, with
edges requiring both positions and the values to increase strictly.

## Sources and provenance

- Yang, Huang, and Chao, [“A fast algorithm for computing a longest common
  increasing subsequence”](https://doi.org/10.1016/j.ipl.2004.10.014), defines
  LCIS and gives an `O(nm)` algorithm.
- Duraj, [“A Sub-Quadratic Algorithm for the Longest Common Increasing
  Subsequence Problem”](https://doi.org/10.4230/LIPIcs.STACS.2020.41), defines
  matching index pairs and the strict partial order that forms the basis of
  the independent DAG reference.
- Zhu, Wang, Wang, and Wang, [“A simple linear space algorithm for computing
  a longest common increasing subsequence”](https://arxiv.org/abs/1608.07002),
  independently records the `O(nm)` LCIS dynamic-programming baseline.
- The [Algovault README index](https://github.com/sgtlaugh/algovault) was used
  only to discover its “Longest Common Increasing Subsequence” title. No
  repository code was read or reused.

The ports and workload are clean-room. See [RIGHTS.md](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) covers empty inputs, duplicates, strictness,
negative values, crossing matches, maximum dimensions, malformed frames, and
the maximum parseable trailing-word probe. The two algorithm references and
ten ports are listed in [`INVENTORY.md`](INVENTORY.md). The static inventory
helper is [`check_inventory.py`](check_inventory.py); it has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/longest_common_increasing_subsequence.c`](../../../c/l/longest_common_increasing_subsequence.c) |
| C3 | [`c3/l/longest_common_increasing_subsequence.c3`](../../../c3/l/longest_common_increasing_subsequence.c3) |
| C++ | [`cpp/l/longest_common_increasing_subsequence.cpp`](../../../cpp/l/longest_common_increasing_subsequence.cpp) |
| Elisa | [`elisa/l/longest_common_increasing_subsequence.elisa`](../../../elisa/l/longest_common_increasing_subsequence.elisa) |
| Mojo | [`mojo/l/longest_common_increasing_subsequence.mojo`](../../../mojo/l/longest_common_increasing_subsequence.mojo) |
| Nim | [`nim/l/longest_common_increasing_subsequence.nim`](../../../nim/l/longest_common_increasing_subsequence.nim) |
| Odin | [`odin/l/longest_common_increasing_subsequence.odin`](../../../odin/l/longest_common_increasing_subsequence.odin) |
| Rust | [`rust/l/longest_common_increasing_subsequence.rs`](../../../rust/l/longest_common_increasing_subsequence.rs) |
| V | [`v/l/longest_common_increasing_subsequence.v`](../../../v/l/longest_common_increasing_subsequence.v) |
| Zig | [`zig/l/longest_common_increasing_subsequence.zig`](../../../zig/l/longest_common_increasing_subsequence.zig) |
