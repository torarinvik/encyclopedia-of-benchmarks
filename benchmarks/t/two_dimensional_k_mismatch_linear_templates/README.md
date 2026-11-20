# Two-dimensional one-mismatch linear-template matching

This profile implements the `k`-mismatch extension of the static linear
templates from Section 4 of Kärkkäinen and Ukkonen's two-dimensional matching
algorithm. It fixes `k=1`, `p=1`, and two disjoint witnesses per candidate.
Pattern samples have length `q = ceil(log_4(m²))` and spacing
`h = floor(m/q)`. Every `m` consecutive text rows contain exactly two test
rows; each test row is sampled at columns `0,h,2h,...`. Pattern sample
addresses are indexed by their base-4 sample values. A positive sample makes
its candidate eligible for full verification, which stops after two
mismatches and accepts Hamming distance at most one.

Input is `[text_side,pattern_side,text...,pattern...]`, with
`3 <= pattern_side <= text_side <= 12` and symbols in `[0,3]`. Both matrices
are row-major. Output is `[match_count,(row,column)...]` as little-endian
signed 64-bit values, ordered by increasing row and then column. Invalid input
returns `-1`; a null output or insufficient capacity returns `-2` without
writing output. The maximum output is 1,608 bytes.

For any window with at most one mismatch, its two witnesses occupy different
rows, so at least one witness is positive. The `p=1` threshold therefore
cannot discard a valid window. The fixed implementation indexes at most
`m*floor(m/q)` pattern samples and stores bounded candidate and result flags.
Its worst-case time is `O(n²m²)` because every candidate reached by the filter
may be verified; the paper's expected-time analysis assumes uniform
independent symbols and its prescribed parameter optimization.

This is an approximate profile and returns locations with Hamming distance
zero or one. It complements the exact
[Kärkkäinen–Ukkonen profile](../two_dimensional_optimal_expected_matching/README.md),
which returns only exact matches, and the
[Bird–Baker row-reduction profile](../two_dimensional_string_matching/README.md).

Sources: Kärkkäinen and Ukkonen, [“Two- and Higher-Dimensional Pattern
Matching in Optimal Expected Time”](https://doi.org/10.1137/S0097539794275872),
Sections 4 and 6.2 and Lemma 6.1; and [“Multidimensional String Matching,”
Encyclopedia of Algorithms](https://doi.org/10.1007/978-1-4939-2864-4_247).
The ports are clean-room implementations of the algorithm description; no
source code or protected text was reused.

| Language | Port |
|---|---|
| C | `c/t/two_dimensional_k_mismatch_linear_templates.c` |
| C3 | `c3/t/two_dimensional_k_mismatch_linear_templates.c3` |
| C++ | `cpp/t/two_dimensional_k_mismatch_linear_templates.cpp` |
| Elisa | `elisa/t/two_dimensional_k_mismatch_linear_templates.elisa` |
| Mojo | `mojo/t/two_dimensional_k_mismatch_linear_templates.mojo` |
| Nim | `nim/t/two_dimensional_k_mismatch_linear_templates.nim` |
| Odin | `odin/t/two_dimensional_k_mismatch_linear_templates.odin` |
| Rust | `rust/t/two_dimensional_k_mismatch_linear_templates.rs` |
| V | `v/t/two_dimensional_k_mismatch_linear_templates.v` |
| Zig | `zig/t/two_dimensional_k_mismatch_linear_templates.zig` |

The package includes a witness-filter reference and an independent exhaustive
reference. The `i64_array_bytes_output` runner and verifier register all ten
language ports and use separate primary and exhaustive references. The profile
is also listed in the repository catalog and Chapter 247 crosswalk. No port has
been compiled or run.
