# Suffix-tray pattern query

This bounded profile builds a compact suffix tree and transforms it into the
static suffix-tray index described in Chapter 422 and in Cole, Kopelowitz, and
Lewenstein's primary paper. Its query follows sigma nodes through either a
small alphabet map or a separating-character decision, then switches to an
LCP-aware binary search in the selected suffix-array interval. This is a
hybrid-index workload, not a full scan of the suffix array.

The profile is distinct from [`suffix_array_lcp_search`](../suffix_array_lcp_search/README.md),
which performs lower/upper search over the whole suffix array, and
[`suffix_tree_pattern_occurrences`](../suffix_tree_pattern_occurrences/README.md),
which follows compressed suffix-tree edges and enumerates matching leaves.
Here sigma-threshold nodes and suffix intervals determine when the query
switches from tree navigation to a local suffix-array search.

## Contract

The ABI is `i64_array_bytes_output`; the symbol is
`suffix_tray_pattern_query`. Input is
`[sigma,n,q,text[n],pattern[q]]`. The alphabet size is `2<=sigma<=4`, the text
length is `1<=n<=12`, and the pattern length is `1<=q<=8`. Text and pattern
symbols are integers in `[0,sigma)`. The constructor appends a unique terminal
symbol ordered below the text alphabet, so its suffix array has the ordinary
lexicographic order of the finite text suffixes.

The maximum valid input is 23 i64 words; the parser accepts 24 words to encode
a one-word trailing-data probe. The bounded constructor inserts all suffixes
into a compact trie and derives the suffix array by direct comparison. These
small-domain adapters build the input structures and make no linear-time
construction claim.

For a suffix-tree node, the tray construction marks it as a sigma node when
its subtree has at least `sigma` leaves. A node with at least two sigma
children stores an alphabet-indexed map to those children or to the
suffix-interval node between them. A sigma node with one sigma child stores
that child's first edge symbol as a separator and routes lower/higher symbols
to its left/right interval. Nodes with no sigma child become one suffix
interval. Edge labels between retained sigma nodes are compared directly
against the pattern. At an interval, an LCP-aware binary search locates the
first matching suffix-array rank.

Output is two little-endian signed-i64 words `[found,position]`. A match has
`found=1` and `position` equal to the text offset of the leftmost matching
suffix in suffix-array order. Absence is `[0,-1]`. The maximum output is 16
bytes. Invalid input returns `-1`; a null output or capacity below 16 returns
`-2` without writing. Workspace is capped at 16,384 bytes for the bounded
tree, tray maps/intervals, suffix array, query state, and staged output.

The static query follows §3.1–3.3 of the source, but the profile does not
claim the paper's asymptotic construction bound because its bounded suffix
tree and suffix-array adapters use direct insertion and comparison. The
query's tree-to-interval path and LCP-aware local search are the measured
algorithmic core. The independent reference sorts all suffixes directly and
checks them one by one; it does not construct a tray.

## Sources and rights

Aluru's “Text Indexing,” Chapter 422, *Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_422](https://doi.org/10.1007/978-1-4939-2864-4_422),
provides the chapter context. The operational suffix-tray definitions,
construction, and query path come from Cole, Kopelowitz, and Lewenstein,
[“Suffix Trays and Suffix Trists: Structures for Faster Text Indexing,”
ICALP 2006, §3.1–3.3, DOI 10.1007/11786986_32](https://doi.org/10.1007/11786986_32).
Only algorithm descriptions were consulted. No source code, prose, figures,
examples, or tests were copied; see [RIGHTS.md](RIGHTS.md).

## Package files

`primary_oracle.py` builds and queries a bounded suffix tray.
`independent_oracle.py` uses direct suffix sorting and scanning.
`workload.json` pins valid, absent, boundary, and ABI cases. Package-local
inventory helpers are static metadata and have not been run.

| Language | Source |
|---|---|
| C | [`c/s/suffix_tray_pattern_query.c`](../../../c/s/suffix_tray_pattern_query.c) |
| C3 | [`c3/s/suffix_tray_pattern_query.c3`](../../../c3/s/suffix_tray_pattern_query.c3) |
| C++ | [`cpp/s/suffix_tray_pattern_query.cpp`](../../../cpp/s/suffix_tray_pattern_query.cpp) |
| Elisa | [`elisa/s/suffix_tray_pattern_query.elisa`](../../../elisa/s/suffix_tray_pattern_query.elisa) |
| Mojo | [`mojo/s/suffix_tray_pattern_query.mojo`](../../../mojo/s/suffix_tray_pattern_query.mojo) |
| Nim | [`nim/s/suffix_tray_pattern_query.nim`](../../../nim/s/suffix_tray_pattern_query.nim) |
| Odin | [`odin/s/suffix_tray_pattern_query.odin`](../../../odin/s/suffix_tray_pattern_query.odin) |
| Rust | [`rust/s/suffix_tray_pattern_query.rs`](../../../rust/s/suffix_tray_pattern_query.rs) |
| V | [`v/s/suffix_tray_pattern_query.v`](../../../v/s/suffix_tray_pattern_query.v) |
| Zig | [`zig/s/suffix_tray_pattern_query.zig`](../../../zig/s/suffix_tray_pattern_query.zig) |

The byte-output runner, independent verifier, catalog, and Chapter 422
crosswalk are registered. This package received a source-only review; no
programs, scripts, tests, helpers, builds, or compilers were run.
