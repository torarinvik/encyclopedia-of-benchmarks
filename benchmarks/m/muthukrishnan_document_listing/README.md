# Muthukrishnan document listing

This package benchmarks the document-listing stage of Muthukrishnan's suffix
array method. A document array maps every suffix-array rank to the document
containing that suffix. For each supplied inclusive rank interval, the
previous-occurrence array and a range-minimum structure report one rank for
each distinct document in the interval.

## Contract

The `i64_array_bytes_output` input is
`[N,D,Q,DA[0..N),(lo_0,hi_0),...,(lo_(Q-1),hi_(Q-1))]`. Bounds are
`1<=N<=32`, `1<=D<=8`, and `1<=Q<=16`. Every `DA[i]` is in `[0,D)`. Each
inclusive interval satisfies `0<=lo<=hi<N`. The exact frame length is
`3+N+2Q`; the maximum valid length is 67 words and the parseable bound is 68
words, allowing a trailing-word rejection probe. Invalid or null input returns
`-1`.

Preprocessing builds `C[i]`, the greatest rank below `i` with the same document
ID as `DA[i]`, or `-1` if none exists. For a query `[lo,hi]`, find the
leftmost position `k` of a minimum of `C` in the current range. If `C[k]>=lo`,
stop on that range. Otherwise report `DA[k]`, recurse on `[lo,k-1]`, then
`[k+1,hi]`, always comparing against the original query's `lo`. Equal minima
choose the leftmost rank. The recursion discovers one witness rank per
distinct document, but its traversal order is not necessarily suffix-rank
order.

The output is a concatenation of `Q` byte records. Each record is
`[document_count, document_id_0,...]` in increasing first-occurrence suffix-rank
order. A count is at most `D`, IDs are bytes, and the maximum output is
`Q*(1+D)=144` bytes. Success
returns the byte count. A null or undersized output returns `-2`, and ports
stage the full bounded result before writing so error returns leave output
untouched.

The primary reference builds a sparse table over `C` and resolves each range
minimum in constant time, then sorts the at most `D` distinct witnesses by
their suffix rank to give the canonical first-occurrence order. Muthukrishnan's
RMQ recursion reports a set, and its traversal order need not equal suffix-rank
order; this bounded sort defines only the byte serialization order. The
independent reference directly scans each interval and emits the first
occurrence of each document, without a previous-occurrence array or RMQ. The
primary takes `O(N log N + QD log D)` time; the independent scan takes `O(QN)`.
At most `D` positions are reported, so recursion depth is at most `D+1<=9`.
The largest fixed native arrays, including per-query witness
ranks/documents and staged output, total under 1.7 KiB; recursive frames and
small locals fit within the 4,096-byte workspace cap. Caller-owned input/output
memory is excluded.

The profile starts after suffix-array pattern search: callers supply `DA` and
the suffix-rank interval for each query. It does not benchmark suffix-array
construction, pattern search, text concatenation, or compressed-index
operations. The local [`orthogonal_range_reporting_2d`](../orthogonal_range_reporting_2d/README.md)
reports points in geometric rectangles using a range tree; it is not the
previous-occurrence/RMQ document-listing algorithm. The local
[`wavelet_tree`](../wavelet_tree/README.md) serves sequence rank/select and
value-range operations, not distinct-document listing. No existing
document-listing package or active reservation was found. The nearby
[`sequitur_grammar_induction`](../sequitur_grammar_induction/README.md) builds
an online grammar and does not perform retrieval. This package's method is
also distinct from top-k retrieval, which ranks documents rather than listing
all documents in an interval.

## Sources and provenance

The method is Muthukrishnan's document-listing algorithm from “Efficient
Algorithms for Document Retrieval Problems,” *Proceedings of SODA 2002*,
pp. 657–666, [ACM DOI 10.1145/545381.545469](https://doi.org/10.1145/545381.545469).
The book context is Sharma V. Thankachan, “Document Retrieval on String
Collections,” *Encyclopedia of Algorithms*, Chapter 629,
[DOI 10.1007/978-1-4939-2864-4_629](https://doi.org/10.1007/978-1-4939-2864-4_629).
The compact operational exposition of the `DA`, previous-occurrence `C`, and
RMQ recursion is also summarized in Navarro and Mäkinen, [“Compressed Full-Text
Indexes”](https://doi.org/10.1145/1216370.1216372), Section 2.3. These sources
provide algorithmic ideas and definitions only. This bounded input contract,
tie policy, byte encoding, ports, references, and fixtures are independently
authored; no source code, prose, examples, or tests are copied.

## Package artifacts

`workload.json` pins normal, repeated-document, boundary, malformed-frame,
null-pointer, and output-capacity cases. `primary_oracle.py` and
`independent_oracle.py` implement the two reference structures. The package
helpers `verify_workload.py` and `check_inventory.py` are static review tools;
neither is run during authoring. Native ports are listed in `INVENTORY.md` and
`INVENTORY.json`.

| Language | Source |
| --- | --- |
| C | [`c/m/muthukrishnan_document_listing.c`](../../../c/m/muthukrishnan_document_listing.c) |
| C3 | [`c3/m/muthukrishnan_document_listing.c3`](../../../c3/m/muthukrishnan_document_listing.c3) |
| C++ | [`cpp/m/muthukrishnan_document_listing.cpp`](../../../cpp/m/muthukrishnan_document_listing.cpp) |
| Elisa | [`elisa/m/muthukrishnan_document_listing.elisa`](../../../elisa/m/muthukrishnan_document_listing.elisa) |
| Mojo | [`mojo/m/muthukrishnan_document_listing.mojo`](../../../mojo/m/muthukrishnan_document_listing.mojo) |
| Nim | [`nim/m/muthukrishnan_document_listing.nim`](../../../nim/m/muthukrishnan_document_listing.nim) |
| Odin | [`odin/m/muthukrishnan_document_listing.odin`](../../../odin/m/muthukrishnan_document_listing.odin) |
| Rust | [`rust/m/muthukrishnan_document_listing.rs`](../../../rust/m/muthukrishnan_document_listing.rs) |
| V | [`v/m/muthukrishnan_document_listing.v`](../../../v/m/muthukrishnan_document_listing.v) |
| Zig | [`zig/m/muthukrishnan_document_listing.zig`](../../../zig/m/muthukrishnan_document_listing.zig) |

The ten language ports are registered in the shared `i64_array_bytes_output`
runner and verifier. The root catalog and Chapter 629 crosswalk include this
profile.
