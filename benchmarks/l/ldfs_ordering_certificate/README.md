# LDFS ordering certificate

This package computes a bounded Lexicographic Depth-First Search (LDFS)
ordering of a connected undirected simple graph. The first vertex is supplied;
for every later choice, the algorithm selects an unvisited vertex with the
lexicographically greatest sequence of already visited neighbors, listed in
reverse visitation order. Ties go to the lowest vertex ID.

Input is `[n,start,adjacency_mask[n]]`, with `1 <= n <= 8`; each row mask
encodes the undirected neighborhood of a vertex. Disconnected graphs,
self-loops, asymmetric masks, and out-of-range bits are invalid. The output is
`[n,ordering[n],certificate_count,(a,b,c,witness)...]`. For each ordered
triple `a < b < c` in the computed ordering with edge `ac` and nonedge `ab`,
the record contains the earliest-in-order witness `d` between `a` and `b` with
edge `db` and nonedge `dc`. A valid LDFS ordering has a witness for each such
triple by the chapter's four-vertex characterization. The largest output is
234 signed i64 values (1872 bytes). Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing.

This bounded profile implements the search ordering and emits its
four-vertex-characterization witnesses. It does not implement the chapter's
separate LDFS-based minimum path-cover algorithms on cocomparability graphs.

Source: “Unified View of Graph Searching and LDFS-Based Certifying
Algorithms,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_685`](https://doi.org/10.1007/978-1-4939-2864-4_685).
The ports and documentation are clean-room implementations; no book text or
code was copied.

## Ports

| Language | Port |
|---|---|
| C | `c/l/ldfs_ordering_certificate.c` |
| C3 | `c3/l/ldfs_ordering_certificate.c3` |
| C++ | `cpp/l/ldfs_ordering_certificate.cpp` |
| Elisa | `elisa/l/ldfs_ordering_certificate.elisa` |
| Nim | `nim/l/ldfs_ordering_certificate.nim` |
| Odin | `odin/l/ldfs_ordering_certificate.odin` |
| Rust | `rust/l/ldfs_ordering_certificate.rs` |
| V | `v/l/ldfs_ordering_certificate.v` |
| Zig | `zig/l/ldfs_ordering_certificate.zig` |

Primary exact-output oracle: `benchmarks/ldfs_ordering_certificate_oracle.py`.
Independent verifier oracle: `benchmarks/ldfs_ordering_certificate_verifier_oracle.py`.
