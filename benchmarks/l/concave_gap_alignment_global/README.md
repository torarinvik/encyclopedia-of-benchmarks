# Global alignment with concave gap penalties

The chapter title says “Local Alignment,” but its problem definition and
stated algorithm concern global alignment of the full input strings. This
bounded profile uses the exact gap-length recurrence for that source problem:
each diagonal step costs 0 for equal symbols and 1 for unequal symbols; a
contiguous gap of length `k` costs supplied `W(k)`. The finite penalty table is
checked to be nonnegative, nondecreasing, and concave.

Input is `[n,m,X...,Y...,W(1),...,W(max(n,m))]`, with `1<=n,m<=8`, symbols in
`[0,3]`, and gap costs in `[0,100]`. The result is the minimum alignment cost
as one little-endian signed i64. The profile directly evaluates the bounded
exact recurrence; it does not claim the asymptotically accelerated algorithm
from the chapter. Invalid input returns `-1`; null output or insufficient
capacity returns `-2` without writing.

Source: “Local Alignment (with Concave Gap Weights),” DOI
[`10.1007/978-1-4939-2864-4_208`](https://doi.org/10.1007/978-1-4939-2864-4_208).
The implementation is clean-room.

| Language | Port |
|---|---|
| C | `c/l/concave_gap_alignment_global.c` |
| C3 | `c3/l/concave_gap_alignment_global.c3` |
| C++ | `cpp/l/concave_gap_alignment_global.cpp` |
| Elisa | `elisa/l/concave_gap_alignment_global.elisa` |
| Nim | `nim/l/concave_gap_alignment_global.nim` |
| Odin | `odin/l/concave_gap_alignment_global.odin` |
| Rust | `rust/l/concave_gap_alignment_global.rs` |
| V | `v/l/concave_gap_alignment_global.v` |
| Zig | `zig/l/concave_gap_alignment_global.zig` |
