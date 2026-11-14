# Lossy Counting frequency summary

This draft maintains a Lossy Counting summary over a bounded integer stream.
New items receive a count of one and an error equal to the current bucket
number minus one. Existing items increment their count. At every bucket
boundary, entries with `count + error <= bucket_number` are removed. This
differs from Misra–Gries counter cancellation and Space-Saving minimum-counter
replacement.

The intended `i64_array_bytes_output` input is `[width,n,items[n]]`, where
`2<=width<=16`, `0<=n<=64`, item IDs lie in `0..15`, and the length is
exactly `2+n`. Bucket numbers begin at one; the item at zero-based position
`i` belongs to bucket `i/width+1`. An incomplete final bucket is not pruned.
The output is little-endian signed i64 words
`[entry_count,(item,count,error)*entry_count]`, sorted by item ID. Empty input
stream produces `[0]`. Null or malformed input returns -1; null output or
insufficient capacity returns -2 without writes. Maximum valid/parseable input
lengths are 66/67 words; maximum output is 392 bytes.

This fixed-alphabet implementation uses direct indexed counters; it takes
`O(n + 16*(n/width) + 16)` time and `O(16)` words. The bucket rule is based on
Manku and Motwani's 2002 [*Approximate Frequency Counts over Data Streams*](https://www.vldb.org/conf/2002/S10P03.pdf);
code, contract, and references are independently
authored. This snapshot exposes retained counters rather than applying a
separate support threshold.

Ten language drafts, two references, workload, inventory checker, and
byte-output runner/verifier integration are present. Verifier source specifies
small streams, frequency bounds, a maximum-output case, capacity errors, and
null inputs. The Elisa draft uses bounded views and indexed arrays. Nothing has
been compiled or run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/l/lossy_counting_summary.c) |
| C3 | [C3](../../../c3/l/lossy_counting_summary.c3) |
| C++ | [C++](../../../cpp/l/lossy_counting_summary.cpp) |
| Elisa | [Elisa](../../../elisa/l/lossy_counting_summary.elisa) |
| Mojo | [Mojo](../../../mojo/l/lossy_counting_summary.mojo) |
| Nim | [Nim](../../../nim/l/lossy_counting_summary.nim) |
| Odin | [Odin](../../../odin/l/lossy_counting_summary.odin) |
| Rust | [Rust](../../../rust/l/lossy_counting_summary.rs) |
| V | [V](../../../v/l/lossy_counting_summary.v) |
| Zig | [Zig](../../../zig/l/lossy_counting_summary.zig) |
