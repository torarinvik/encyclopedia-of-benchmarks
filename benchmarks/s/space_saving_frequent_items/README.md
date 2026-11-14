# Space-Saving frequent-item summary

This in-progress benchmark maintains a fixed-size Space-Saving summary over an
integer stream. It differs from [`misra_gries_summaries`](../../m/misra_gries_summaries/README.md):
when full, Misra–Gries decrements every counter, while Space-Saving replaces
one minimum counter and records its inherited error.

## Draft contract

The `i64_array_bytes_output` input is `[k,n,items...]`, with `1 <= k <= 8`,
`0 <= n <= 64`, exact length `2+n`, and item IDs in `[-1000,1000]`. On an
existing item increment its estimate. An unseen item uses a free slot with
estimate 1 and error 0; if no slot is free, replace the item with minimum
estimate, breaking ties by smallest item ID, and assign estimate `minimum+1`
and error `minimum`. Output little-endian i64 words
`[candidate_count,(item,estimate,error)*candidate_count]` sorted by item ID.
The empty stream emits `[0]`. Invalid or null input returns `-1`; null output
or insufficient capacity returns `-2` without writes. Maximum valid and
parseable input lengths are 66 and 67 words; maximum output is 200 bytes.

The stored estimate is an upper bound on the current item's true frequency;
the recorded error provides its lower bound as `estimate-error`. With a
linear search over the at-most-eight counters, time is O(nk+k²) including
output sorting and space O(k). This bounded implementation does not claim the
paper's optimized constant-time stream-summary operations.

Source: Metwally, Agrawal and El Abbadi, “Efficient Computation of Frequent
and Top-k Elements in Data Streams” (2005), [publication record](https://dblp.dagstuhl.de/rec/conf/icdt/MetwallyAA05.html).
Only the mathematical algorithm was used; no source code or prose was copied.
The primary reference uses a map; an independent lazy-heap reference also
checks each retained item's frequency bounds. A bounded workload and
[C](../../../c/s/space_saving_frequent_items.c),
[C++](../../../cpp/s/space_saving_frequent_items.cpp),
[Rust](../../../rust/s/space_saving_frequent_items.rs),
[Elisa](../../../elisa/s/space_saving_frequent_items.elisa),
[Odin](../../../odin/s/space_saving_frequent_items.odin),
[Nim](../../../nim/s/space_saving_frequent_items.nim),
[Zig](../../../zig/s/space_saving_frequent_items.zig),
[C3](../../../c3/s/space_saving_frequent_items.c3),
[V](../../../v/s/space_saving_frequent_items.v), and
[Mojo](../../../mojo/s/space_saving_frequent_items.mojo) drafts are present. The
byte-output suite has runner and verifier wiring, including reference comparison
and bounded exhaustive stream cases. The workload includes consecutive tied
evictions, and the verifier source includes repeated full-length eviction traces
and a closed-form single-counter invariant. It also specifies exact counts when
all distinct items fit and checks conservation of total estimated counts for
repeated evictions. Static review remains in progress; nothing has been executed.
