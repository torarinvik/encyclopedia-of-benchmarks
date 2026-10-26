# Weighted random sampling with supplied rational priorities

This bounded profile implements Algorithm A from the source chapter: assign
each item the key `U^(1/w)` and select the `m` largest keys. The random values
are supplied as exact rationals, so key comparisons use integer exponentiation
and cross multiplication rather than floating-point logarithms or roots.

Input is `[n,m,(weight,numerator,denominator)...]`, with `1 <= n <= 16`,
`1 <= m <= n`, weights in `[1,3]`, and `U=numerator/denominator` satisfying
`1 <= numerator < denominator <= 100`. Output is the selected zero-based item
IDs in decreasing-key order; ties go to lower IDs. Values use little-endian
signed i64 encoding. Invalid input returns `-1`; null output or insufficient
capacity returns `-2` without writing.

For supplied rational `U`, this preserves the source key ordering exactly.
Finite rational inputs are a deterministic fixture projection and do not
claim to reproduce the ideal continuous random probability law.

Source: “Weighted Random Sampling,” DOI
[`10.1007/978-1-4939-2864-4_478`](https://doi.org/10.1007/978-1-4939-2864-4_478).
This profile is clean-room; no book prose or source code is copied.

| Language | Port |
|---|---|
| C | `c/w/weighted_random_sampling.c` |
| C3 | `c3/w/weighted_random_sampling.c3` |
| C++ | `cpp/w/weighted_random_sampling.cpp` |
| Elisa | `elisa/w/weighted_random_sampling.elisa` |
| Nim | `nim/w/weighted_random_sampling.nim` |
| Odin | `odin/w/weighted_random_sampling.odin` |
| Rust | `rust/w/weighted_random_sampling.rs` |
| V | `v/w/weighted_random_sampling.v` |
| Zig | `zig/w/weighted_random_sampling.zig` |
