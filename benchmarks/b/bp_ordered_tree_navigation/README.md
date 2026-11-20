# BP ordered-tree navigation

This package profiles the chapter's depth-first balanced-parenthesis (BP)
representation and the excess-search kernel described for the fully functional
BP structure. A node contributes an open bit `1` on entry and a close bit `0`
on exit. Bits are emitted by a left-to-right depth-first traversal of the
ordered tree. The bit string has `2*n` bits.

The signed-i64 input is:

```text
[n, q, parent[1..n-1], (opcode, first, second) * q]
```

`n` is 1 through 31 and `q` is 0 through 32. Vertex 0 is the root; each
later vertex has a parent ID smaller than its own ID, and sibling order is
ascending vertex ID. The n<=31 bound keeps the 2*n bit encoding in a signed
64-bit output word. Opcodes are:

| Opcode | Query | `first` | `second` | Answer |
|---|---|---|---|---|
| 0 | forward excess search | prefix index `i` in 0..2n | delta `d` in -2n..2n | least `j>i` with E[j]=E[i]+d; sentinel 2n+1 if absent |
| 1 | backward excess search | prefix index `i` in 0..2n | delta `d` in -2n..2n | greatest `j<i` with E[j]=E[i]+d; fallback 0 |
| 2 | range minimum excess (`RMQi`) | bit-position range start `l` | inclusive end `r` | leftmost bit position minimizing E[position+1] |
| 3 | `findclose` | open-bit position | 0 | matching close-bit position |
| 4 | `findopen` | close-bit position | 0 | matching open-bit position |
| 5 | `enclose` | open-bit position | 0 | parent open-bit position, or -1 for the root |

`E[k]` is the excess after the first `k` bits, with `E[0]=0`. Search queries
use excess-prefix indices, which include the baseline position 0 and terminal
position `2n`; matching and RMQi queries use zero-based bit positions. A
matching opcode applied to the wrong parenthesis kind is invalid input. This
maps the chapter's one-based BP position `i` to bit index `i-1` and its excess
`E[i]` to this profile's `E[i]` prefix entry. Thus RMQi over bits `[l,r]`
minimizes `E[position+1]`, exactly mapping the chapter's inclusive BP-entry
interval. `findclose` converts the forward-search prefix result back to a bit
position; `findopen` and nonroot `enclose` convert the backward-search prefix
result directly to the opening-bit position. The root has no enclosing open
parenthesis, so this profile returns `-1` for root `enclose`; it special-cases
the chapter formula's no-match fallback for that semantic case.

Output is a little-endian signed-i64 word array:

```text
[n, bit_length, packed_bp_bits, q, answer[0..q-1]]
```

Bit `j` of the BP sequence is bit `j` of `packed_bp_bits`, least-significant
bit first. The maximum valid input is 128 words; 129 words are accepted to
classify one trailing word as invalid. Maximum output and fixed workspace are
288 and 4096 bytes. Invalid input returns `-1`; null output or insufficient
capacity returns `-2`, without writing bytes.

The primary reference scans the BP excess-prefix array for forward/backward
searches and RMQi, and expresses `findclose`, `findopen`, and `enclose` through
those operations. The independent reference derives matching and enclosing
positions from a direct tree traversal and scans the serialized string for
the excess queries. These are bounded O(n+q*n) profiles; they do not claim the
constant-time indexed range min-max structure from the chapter.

This is separate from the repository's balanced-parenthesis successor and
rank/unrank profiles: those operate on strings in the balanced-word family,
while this package builds a BP encoding from an ordered tree and exposes the
chapter's excess searches and tree matching operations. It is also separate
from LOUDS and DFUDS, which use different tree encodings and node orders.

Source: “Compressed Tree Representations,” *Encyclopedia of Algorithms*,
[Chapter 641](https://doi.org/10.1007/978-1-4939-2864-4_641), “BP
Representation” and “Fully Functional BP Representation.” The algorithm
description is used as an idea source; ports and workload are clean-room.

## Ports

| Language | Source |
|---|---|
| C | `c/b/bp_ordered_tree_navigation.c` |
| C3 | `c3/b/bp_ordered_tree_navigation.c3` |
| C++ | `cpp/b/bp_ordered_tree_navigation.cpp` |
| Elisa | `elisa/b/bp_ordered_tree_navigation.elisa` |
| Mojo | `mojo/b/bp_ordered_tree_navigation.mojo` |
| Nim | `nim/b/bp_ordered_tree_navigation.nim` |
| Odin | `odin/b/bp_ordered_tree_navigation.odin` |
| Rust | `rust/b/bp_ordered_tree_navigation.rs` |
| V | `v/b/bp_ordered_tree_navigation.v` |
| Zig | `zig/b/bp_ordered_tree_navigation.zig` |
