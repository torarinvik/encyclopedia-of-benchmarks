# All-distances k-mins sketch

This package builds the all-distances **k-mins** sketch for one ordered set of
items. It receives one rank permutation for each independent rank assignment.
For each assignment, it scans items by increasing distance and records an item
exactly when its rank is smaller than every rank at a closer distance. These
records are the minimum-value/distance (MV/D) list: a distance query recovers
the minimum rank among all items no farther than the query threshold.

## Contract

The `i64_array_bytes_output` frame is
`[n,assignment_count,distances[n],rank_rows[assignment_count*n]]`. Distances
are strictly increasing, nonnegative values. Each rank row is a permutation of
`0..n-1`; rows are caller-supplied realizations of independent rank functions,
and repeated rows are valid. The bounds are `1<=n<=6`, `1<=assignment_count<=3`,
and `0<=distance<=1,000,000`. Input is row-major after the distances, with each
rank assignment occupying one complete row.

Output is `[record_count,(assignment_id,item_id,rank,distance)*]` encoded as
little-endian signed 64-bit words. Records are ordered first by assignment ID,
then by increasing distance. A record is emitted when that item changes the
minimum rank for its assignment's distance prefix. The maximum frame is 26
words; the maximum output is `1+4*6*3=73` words, or 584 bytes. Invalid input
returns `-1`. For valid input, null or short output returns `-2` without writes;
input validity is checked before output capacity.

This is a deterministic replay of supplied rank functions and distance order.
It does not generate randomness or claim the expected sketch-size bounds. It
differs from [`all_distances_sketch_bottom_k`](../all_distances_sketch_bottom_k/README.md),
which keeps a shared without-replacement bottom-k set at each distance prefix.
It also extends [`min_hash_k_mins`](../../m/min_hash_k_mins/README.md)'s
single whole-set minimum into one MV/D record list per rank assignment and
distance prefix.

## References and files

The primary reference applies the incremental prefix-minimum update. The
independent reference asks the minimum-rank query at each distance threshold
and records changes in the answer. Bounded fixtures are in `workload.json`.
The ten language ports are registered with the `i64_array_bytes_output`
runner and verifier.

| Language | Source |
|---|---|
| C | [`c/a/all_distances_sketch_k_mins.c`](../../../c/a/all_distances_sketch_k_mins.c) |
| C3 | [`c3/a/all_distances_sketch_k_mins.c3`](../../../c3/a/all_distances_sketch_k_mins.c3) |
| C++ | [`cpp/a/all_distances_sketch_k_mins.cpp`](../../../cpp/a/all_distances_sketch_k_mins.cpp) |
| Elisa | [`elisa/a/all_distances_sketch_k_mins.elisa`](../../../elisa/a/all_distances_sketch_k_mins.elisa) |
| Mojo | [`mojo/a/all_distances_sketch_k_mins.mojo`](../../../mojo/a/all_distances_sketch_k_mins.mojo) |
| Nim | [`nim/a/all_distances_sketch_k_mins.nim`](../../../nim/a/all_distances_sketch_k_mins.nim) |
| Odin | [`odin/a/all_distances_sketch_k_mins.odin`](../../../odin/a/all_distances_sketch_k_mins.odin) |
| Rust | [`rust/a/all_distances_sketch_k_mins.rs`](../../../rust/a/all_distances_sketch_k_mins.rs) |
| V | [`v/a/all_distances_sketch_k_mins.v`](../../../v/a/all_distances_sketch_k_mins.v) |
| Zig | [`zig/a/all_distances_sketch_k_mins.zig`](../../../zig/a/all_distances_sketch_k_mins.zig) |

## Provenance

The method follows Cohen and Kaplan, “Summarizing Data using Bottom-k
Sketches,” Section 4, [DOI 10.1145/1281100.1281133](https://doi.org/10.1145/1281100.1281133),
which defines all-distances k-mins and the MV/D list, as summarized in
*Encyclopedia of Algorithms*, Chapter 574,
[DOI 10.1007/978-1-4939-2864-4_574](https://doi.org/10.1007/978-1-4939-2864-4_574).
All ports and references are clean-room implementations. No book prose, figures,
source code, or upstream fixtures are reproduced; see `RIGHTS.md`.
