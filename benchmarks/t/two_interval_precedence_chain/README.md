# Two-interval precedence chain

This package selects a maximum-cardinality chain under the chapter's
precedence-only 2-interval model. Each item consists of two disjoint closed
integer intervals `[a,b]` and `[c,d]` with `a < b < c < d`. One 2-interval
precedes another when both of its component intervals end strictly before the
corresponding component intervals of the other begin. A feasible selected set
is a chain in this relation, so all selected 2-intervals are pairwise disjoint
and in the same precedence order on both tracks.

Input is `[n,a_0,b_0,c_0,d_0,...]`, with `1 <= n <= 16` and endpoints in
`[0,63]`. The output is `[chain_length,item_id_0,...]`, where IDs refer to
input order. Among equal-length chains, the lexicographically smallest ID
sequence wins. The maximum output is 17 signed i64 values (136 bytes). Invalid
input returns `-1`; null output or insufficient capacity returns `-2` without
writing.

This package implements only the precedence-only model from the chapter; it
does not allow nesting or crossing between selected 2-intervals and does not
claim to solve the other compatibility variants surveyed there.

Source: “Two-Interval Pattern Problems,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_445`](https://doi.org/10.1007/978-1-4939-2864-4_445).
The package is clean-room work; no textbook wording or code was copied.

## Ports

| Language | Port |
|---|---|
| C | `c/t/two_interval_precedence_chain.c` |
| C3 | `c3/t/two_interval_precedence_chain.c3` |
| C++ | `cpp/t/two_interval_precedence_chain.cpp` |
| Elisa | `elisa/t/two_interval_precedence_chain.elisa` |
| Nim | `nim/t/two_interval_precedence_chain.nim` |
| Odin | `odin/t/two_interval_precedence_chain.odin` |
| Rust | `rust/t/two_interval_precedence_chain.rs` |
| V | `v/t/two_interval_precedence_chain.v` |
| Zig | `zig/t/two_interval_precedence_chain.zig` |

Primary oracle: `benchmarks/two_interval_precedence_chain_oracle.py`.
Independent verifier oracle: `benchmarks/two_interval_precedence_chain_verifier_oracle.py`.
