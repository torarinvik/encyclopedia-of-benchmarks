# Static interval tree point stabbing

This profile builds a balanced static binary search tree over closed integer
intervals. Nodes are ordered by `(low, high, input_id)` and store the greatest
high endpoint in their subtree. A query reports every interval containing the
point, preserving identity by returning a bit mask of original input IDs.

The tree is built once per call and then queried for the supplied points. This
benchmarks the CLRS interval-search augmentation and reporting traversal; it
does not benchmark red-black rotations, insertion, or deletion.

## Contract

The exported symbol is `interval_tree_point_stabbing` with the
`i64_array_bytes_output` ABI. Input is a signed 64-bit word array:

```text
[n, q, low_0, high_0, ..., low_(n-1), high_(n-1), point_0, ..., point_(q-1)]
```

- `0 <= n <= 16`, `0 <= q <= 8`; all endpoints and points lie in `[-32, 32]`.
- Intervals are closed and require `low <= high`. Equal or duplicate intervals
  are allowed and retain separate input IDs.
- The frame is exactly `2 + 2*n + q` words. The maximum valid input is 42
  words; 43 words are parseable so an extra trailing word can be rejected.
- Output is `[q, mask_0, ..., mask_(q-1)]`, each word little-endian signed
  64-bit. Bit `i` in a mask is set iff input interval `i` contains that query
  point. The header means even `q=0` returns one 8-byte word.
- Success returns the output byte count. Malformed input returns `-1`;
  null output or insufficient capacity returns `-2`. Validation precedes the
  output-capacity check, and errors leave output untouched.
- Maximum output is 72 bytes. The declared workspace cap is 4,096 bytes,
  including fixed interval, tree-link, subtree-maximum, traversal, and query
  staging arrays plus scalar locals and call frames.

The primary uses insertion sort on at most 16 records, then builds a balanced
tree from the sorted order and computes subtree maxima bottom-up. For each
point it prunes a subtree whose maximum high endpoint is below the point, and
prunes right descendants when their low keys must exceed the point. Its
bounded construction is `O(n^2)` and a query is `O(n)` worst case; fixed
workspace is `O(n+q)`. The independent reference scans all input intervals for
each point in `O(nq)` time and `O(q)` output staging space.

## Source and distinction

The operational method follows the interval-tree augmentation in CLRS §14.3
(third edition; the topic appears as §17.3 in the fourth edition):
nodes are keyed by interval low endpoints and carry the maximum high endpoint
in their subtree. NIST DADS lists the interval-tree topic and cites CLR90;
CLRS supplies the detailed search augmentation used here. This clean-room
profile specializes the tree to a deterministic balanced static build and
all-match point queries. It is distinct from mutable interval-set containers,
discrete interval encoding trees, and multidimensional orthogonal range
reporting.

Sources:

- [The MIT Press, *Introduction to Algorithms*, fourth edition](https://mitpress.mit.edu/9780262046305/introduction-to-algorithms/)
- [NIST DADS, Interval Tree](https://xlinux.nist.gov/dads/HTML/intervaltree.html)

[`workload.json`](workload.json) pins closed endpoints, duplicate identities,
empty cases, maximum input/output, malformed frames, and output-capacity
behavior. `primary_oracle.py` models the augmented tree; `independent_oracle.py`
uses direct scans. The static helpers are source artifacts and are not run in
this task. See [RIGHTS.md](RIGHTS.md) and [INVENTORY.md](INVENTORY.md).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/i/interval_tree_point_stabbing.c`](../../../c/i/interval_tree_point_stabbing.c) |
| C3 | [`c3/i/interval_tree_point_stabbing.c3`](../../../c3/i/interval_tree_point_stabbing.c3) |
| C++ | [`cpp/i/interval_tree_point_stabbing.cpp`](../../../cpp/i/interval_tree_point_stabbing.cpp) |
| Elisa | [`elisa/i/interval_tree_point_stabbing.elisa`](../../../elisa/i/interval_tree_point_stabbing.elisa) |
| Mojo | [`mojo/i/interval_tree_point_stabbing.mojo`](../../../mojo/i/interval_tree_point_stabbing.mojo) |
| Nim | [`nim/i/interval_tree_point_stabbing.nim`](../../../nim/i/interval_tree_point_stabbing.nim) |
| Odin | [`odin/i/interval_tree_point_stabbing.odin`](../../../odin/i/interval_tree_point_stabbing.odin) |
| Rust | [`rust/i/interval_tree_point_stabbing.rs`](../../../rust/i/interval_tree_point_stabbing.rs) |
| V | [`v/i/interval_tree_point_stabbing.v`](../../../v/i/interval_tree_point_stabbing.v) |
| Zig | [`zig/i/interval_tree_point_stabbing.zig`](../../../zig/i/interval_tree_point_stabbing.zig) |
