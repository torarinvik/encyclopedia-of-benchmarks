# Three-list 2-threshold intersection

This profile implements the `t`-threshold procedure of Barbay and Kenyon for
exactly three sorted sets with `t=2`. It returns every value present in at
least two lists. The implementation follows Algorithm 3 in Section 4.2 of
“Adaptive Intersection and t-Threshold Problems”: it keeps green lists that
contain the current candidate, red lists with their next representative in
`H`, and at most one white list searched in round-robin order. A white-list
search makes one exponential-search step at a time and completes with binary
search when it reaches or passes the candidate. The loop emits a candidate
when two lists are green and advances when two lists are red.

For this fixed three-list profile, `H` is represented by up to three red
representatives and its minimum is selected by a deterministic list-ID scan.
This gives the same candidate order as a minimum heap for the bounded `k=3`
case. All ties between equal representatives are promoted together. When a
choice among green lists is needed, the lowest list ID is chosen; the
round-robin cursor advances by list ID.

Input is `[n1,A1...,n2,A2...,n3,A3...]`, with each list length in `[1,32]`.
Each list is strictly increasing and each value is a signed 32-bit integer;
the frame itself uses signed 64-bit words. Output is
`[count,value_0,...]` as little-endian signed 64-bit values, in ascending
order. Invalid input returns `-1`; a null output or insufficient capacity
returns `-2` without writing output. Because each reported value uses at
least two of the 96 total input-list slots, at most 48 values qualify; the
maximum output is 392 bytes.

The resulting threshold set is a set, so values occurring in all three input
lists appear once. This differs from
[`sorted_arrays_intersection`](../sorted_arrays_intersection/README.md),
which computes the full intersection of three lists, and from
[`inverted_list_bitvector_intersection`](../inverted_list_bitvector_intersection/README.md),
which computes full intersection by word-wise AND. The two-list full
intersection profile also differs in its threshold semantics. The threshold
operation is not a wrapper around any of those profiles.

The Encyclopedia chapter’s DOI is
[10.1007/978-1-4939-2864-4_628](https://doi.org/10.1007/978-1-4939-2864-4_628).
It cites the primary algorithm source: Jérémy Barbay and Claire Kenyon,
[“Adaptive Intersection and t-Threshold Problems”](https://doi.org/10.1145/545381.545432),
Proceedings of SODA 2002, Sections 4 and 4.2, Algorithm 3. The source defines
the output as the values present in at least `t` of `k` ordered sets and gives
the initialization, color transitions, representative heap, doubling-search
step, and binary-search completion. This package is a bounded clean-room
specialization and does not reproduce source code.

| Language | Port |
|---|---|
| C | `c/t/t_threshold_three_sorted_lists.c` |
| C3 | `c3/t/t_threshold_three_sorted_lists.c3` |
| C++ | `cpp/t/t_threshold_three_sorted_lists.cpp` |
| Elisa | `elisa/t/t_threshold_three_sorted_lists.elisa` |
| Mojo | `mojo/t/t_threshold_three_sorted_lists.mojo` |
| Nim | `nim/t/t_threshold_three_sorted_lists.nim` |
| Odin | `odin/t/t_threshold_three_sorted_lists.odin` |
| Rust | `rust/t/t_threshold_three_sorted_lists.rs` |
| V | `v/t/t_threshold_three_sorted_lists.v` |
| Zig | `zig/t/t_threshold_three_sorted_lists.zig` |

The package includes a state-machine reference and an independent direct
membership-count reference. Shared suite registration is handled separately.
