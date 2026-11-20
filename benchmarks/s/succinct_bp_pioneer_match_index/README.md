# Succinct BP pioneer-family matching index

This package measures construction and use of a bounded recursive
pioneer-family index for a balanced-parenthesis bit string. It answers the
matching-parenthesis operation in both directions for every input position.
The profile is deliberately bounded and uses fixed block length `B=8` plus a
direct-table base case at 16 parentheses. Those constants make the recursive
profile portable; they are refinements of the paper's asymptotic choices and
do not claim a `2n+o(n)` representation or constant-time operations.

Input is `[n, bit[0..2n-1]]`, with `1<=n<=32` and exactly `2n` symbols. A bit
of 1 is an opening parenthesis and 0 is a closing parenthesis. The sequence
must be balanced. Output is a little-endian signed-i64 byte array
`[2n, mate[0],...,mate[2n-1]]`. Positions are zero-based; every entry names
the matching opposite parenthesis. The valid input maximum is 65 i64 words,
the parser accepts up to 66 words to classify one trailing word as malformed,
the maximum output is 520 bytes, and the declared fixed workspace is 8,192
bytes. Invalid input returns -1. A null or undersized output returns -2 after
the input has been validated, with no output bytes written.

At each recursive build level the primary makes one temporary stack pass to
classify matches. It retains exact positions only for same-block matches. For
far positions, the builder may use a temporary per-position target-block array
while selecting pioneers and filling ordered summary lists keyed by source
block, target block, and absolute boundary excess (`depth[p]` for an opening,
`depth[p+1]` for a closing). It then discards both that array and the
temporary match map. The retained summaries contain ordered positions grouped
under those keys; they do not retain a per-position destination or matching-
position answer. The builder
marks positions whose mates lie outside their `B=8` block as far, then selects
opening and closing pioneers. For an opening far position `p`, the previous
far opening in the same source block is a pioneer when its mate is in another
block; the first far opening in a source block is also a pioneer. Closing
pioneers are selected symmetrically from right to left. The pioneer family is
the sorted, duplicate-free set containing each pioneer and its mate. Its
parenthesis subsequence is balanced and is recursively indexed. Since the
family has at most `4*ceil(L/8)-6` positions at a non-base level of length `L`
and `L>16`, recursion shrinks; at most three levels are built for 64 input
symbols.

For a far query, the primary follows the preceding opening pioneer (or
following closing pioneer) into the recursive family. It maps the recursively
matched child position back through the family to recover the anchor position
and its target block. The query never uses a stored per-position destination or
far-mate answer. It selects a source summary by source block, the recursively
recovered target block, and boundary excess; the query's rank in that ordered
position list selects the same-rank opposite-parenthesis position in the
reverse-direction summary. This is the finite block-lookup refinement of the paper's local
right-/left-excess lookup; equal-depth openings and their closes occur in the
same left-to-right order. Same-block pairs and recursive strings of at most 16
symbols use the direct local table. The primary performs
`O(n)` matching/index construction and at most `O(n)` bounded table work per
reported position, for `O(n^2)` total worst-case work under this fixed profile.
The independent reference uses one global stack and returns the complete mate
vector without pioneer classification or recursion.

The local `rank_select_bitstring` package supplies bit-vector rank/select but
does not match parentheses. `bp_ordered_tree_navigation` builds an ordered-tree
BP string and evaluates bounded excess scans; it does not build a recursive
pioneer-family index. Parenthesis generation/successor packages enumerate or
transform Dyck words and do not provide this matching index.

Source context: Meng He, “Succinct Data Structures for Parentheses Matching,”
*Encyclopedia of Algorithms*, Chapter 410,
[DOI 10.1007/978-1-4939-2864-4_410](https://doi.org/10.1007/978-1-4939-2864-4_410).
The operational pioneer-family method follows Geary, Rahman, Raman, and Raman,
[“A Simple Optimal Representation for Balanced Parentheses,” §§2.1–2.3](https://doi.org/10.1016/j.tcs.2006.09.014).
Only algorithm descriptions were used. This package contains clean-room
implementations and does not copy source code, prose, examples, or tests.

Primary reference: [`primary_oracle.py`](primary_oracle.py). Independent
reference: [`independent_oracle.py`](independent_oracle.py). Workload:
[`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | `c/s/succinct_bp_pioneer_match_index.c` |
| C3 | `c3/s/succinct_bp_pioneer_match_index.c3` |
| C++ | `cpp/s/succinct_bp_pioneer_match_index.cpp` |
| Elisa | `elisa/s/succinct_bp_pioneer_match_index.elisa` |
| Mojo | `mojo/s/succinct_bp_pioneer_match_index.mojo` |
| Nim | `nim/s/succinct_bp_pioneer_match_index.nim` |
| Odin | `odin/s/succinct_bp_pioneer_match_index.odin` |
| Rust | `rust/s/succinct_bp_pioneer_match_index.rs` |
| V | `v/s/succinct_bp_pioneer_match_index.v` |
| Zig | `zig/s/succinct_bp_pioneer_match_index.zig` |

The profile is registered with `i64_array_bytes_output`; the shared runner,
verifier, catalog, and root README include the package.
