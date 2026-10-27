# Permutation reverse-search enumeration

This profile implements the chapter's permutation-specific reverse search.
The root is the identity. For each other permutation, its parent is obtained
by swapping the first adjacent descent. The reverse point is that first
descent's 1-based position, or `n` at the identity. Children are visited by
swapping positions `i` and `i+1` for `i=1,...,r-1`, followed by the one
additional child at `i=r+1` when `r+2<=n` and `p_r<p_(r+2)`. The traversal is
depth-first preorder, so it emits each permutation before its descendants.

Input is `[n]`, with `1<=n<=4`. Output is a little-endian signed 64-bit word
stream containing `[n!, permutation rows in reverse-search preorder]`. Rows
are flattened in order. For example, at `n=3` the rows are `123, 213, 231,
321, 132, 312`. Invalid input returns `-1`; null output or insufficient
capacity returns `-2` without writing. The maximum output is 776 bytes.

The primary oracle implements the reverse-point child rule. The independent
verifier computes the parent of every candidate permutation and traverses the
resulting child relation sorted by the adjacent-swap position. This is the
chapter's permutation reverse-search tree, not the partition-search order or
the adjacent-swap Gray-code order.

Primary oracle: [`reverse_search_permutation_enumeration_oracle.py`](../../reverse_search_permutation_enumeration_oracle.py).
Independent verifier: [`reverse_search_permutation_enumeration_verifier_oracle.py`](../../reverse_search_permutation_enumeration_verifier_oracle.py).

Source: “Permutation Enumeration,” Katsuhisa Yamanaka, *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_735`](https://doi.org/10.1007/978-1-4939-2864-4_735).
The chapter is used only for algorithm attribution and mathematical rules; no
book code, prose, or figures were copied.

## Workload and ports

The [workload](workload.json) includes a complete maximum-size output, a
nontrivial three-element traversal, malformed bounds and length, null buffers,
and an insufficient-capacity case.

| Language | Port |
|---|---|
| C | `c/r/reverse_search_permutation_enumeration.c` |
| C3 | `c3/r/reverse_search_permutation_enumeration.c3` |
| C++ | `cpp/r/reverse_search_permutation_enumeration.cpp` |
| Elisa | `elisa/r/reverse_search_permutation_enumeration.elisa` |
| Nim | `nim/r/reverse_search_permutation_enumeration.nim` |
| Odin | `odin/r/reverse_search_permutation_enumeration.odin` |
| Rust | `rust/r/reverse_search_permutation_enumeration.rs` |
| V | `v/r/reverse_search_permutation_enumeration.v` |
| Zig | `zig/r/reverse_search_permutation_enumeration.zig` |
