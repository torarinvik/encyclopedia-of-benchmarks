# Arbitrary-order bottom-k all-distances interval updates

This package benchmarks the interval-update method for maintaining one
bottom-`k` all-distances sketch when items arrive in arbitrary distance order.
It is the Section 5 arbitrary-insertion method, not the distance-sorted prefix
construction in `all_distances_sketch_bottom_k` or the independent MV/D record
construction in `all_distances_sketch_k_mins`.

## Contract

ABI: `i64_array_bytes_output`; symbol: `all_distances_bottom_k_interval_updates`.
Input is `[n,k,(item_id,distance,rank)*n]` in arrival order. `2<=k<=4` and
`k<=n<=32`; item IDs and ranks are separate permutations of `0..n-1`, and
distances are distinct integers in `0..1,000,000`. The first `k` records are
the `k` nearest items in strictly increasing distance order and initialize the
sketch. Every later item is farther than those seeds, but later arrivals may
be in any order. This provides a valid initial state with `k` active items at
every subsequent insertion distance without adding an unprovided empty-state
rule.

Each retained item is represented by a half-open interval `[start,end)` over
integer query radii `0..1,000,000`; `1,000,001` is the past-the-domain
sentinel. At a radius, the bottom-`k` sketch is the `k` least-rank items whose
distance is at most that radius, or all such items if fewer than `k` exist.
For each arrival `z` at distance `d`, find the largest-rank interval covering
`d`. If `rank(z)` is smaller, truncate that interval at `d`; then walk its
successive right-end boundaries, truncating the largest-rank interval there
while its rank is larger than `rank(z)`. Insert `z` on `[d,next_boundary)`.
If `z` does not beat the current maximum rank, it is never inserted. Unique
ranks and distances eliminate ties. The output is `[r,(item_id,start,end)*r]`,
sorted by `(start,item_id)`; each item appears at most once.

Malformed input returns `-1`. For valid input, null or undersized output
returns `-2` without writes. The largest frame has 98 i64 words and the parser
accepts at most 99 words to bound a trailing-value probe. At most `n` intervals
are emitted, so the output cap is `1+3*32=97` words, or 776 bytes. The fixed
workspace cap is 4,096 bytes, including the interval state, parser tables, and
staged output.

The primary reference implements the source's interval split and successive
maximum-rank deletion rule. The independent reference recomputes the exact
bottom-`k` set at each distinct distance threshold and derives each item's
maximal membership interval directly. The direct-scan primary takes
`O(n^3)` worst-case time because each insertion may cross O(n) interval
boundaries and each boundary step scans O(n) intervals. The independent
threshold-recomputation reference takes `O(n^3 log n)` worst-case time due to
sorting eligible items at each threshold. Both use `O(n)` interval/output
storage; all dimensions are capped at 32.

## Sources and duplicate decision

The operational interval update is from Cohen and Kaplan, “Summarizing Data
using Bottom-k Sketches,” §4–5, [DOI 10.1145/1281100.1281133](https://doi.org/10.1145/1281100.1281133).
The topic is also covered by *Encyclopedia of Algorithms*, Chapter 574,
[DOI 10.1007/978-1-4939-2864-4_574](https://doi.org/10.1007/978-1-4939-2864-4_574).
The local bottom-`k` package scans the distance-sorted vertices and emits a
single-source sketch; the local k-mins package emits per-rank prefix minima.
Neither performs arbitrary-arrival interval rewrites. Only algorithmic ideas
and bibliographic details are used; no code, prose, examples, or fixtures are
copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json),
[`INVENTORY.json`](INVENTORY.json), and the two references in this directory.
