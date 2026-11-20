# Order maintenance with cyclic labels

This bounded clean-room profile maintains an ordered list under insert-after
operations and answers relative-order queries. It follows the cyclic-label
approach in the pinned Spaghetti Source `order_maintenance.cc`, which cites
Dietz and Sleator. It deliberately benchmarks insertion and order only; the
pinned `erase` assignments do not update either neighbor link, so deletion is
excluded.

## Contract

- ABI: `i64_array_scalar`, symbol `order_maintenance`.
- Input: `[N,Q,(opcode,a,b)*Q]`, exactly `2+3Q` signed 64-bit words.
- `N` is the insertion capacity, `0<=N<=64`; `Q` is `0..128`.
- Start with a circular sentinel ID `0` and label `0`. New element IDs must be
  sequential from 1.
- `opcode=0` inserts new ID `b` immediately after already-present ID `a`;
  `a=0` inserts after the sentinel.
- `opcode=1` asks whether already-present ID `a` precedes ID `b`. A same-ID
  query is valid and returns false.
- Return the sum of `(one-based operation index)` for each true query. Invalid
  or null input returns `-1`.
- The maximum valid frame has 386 words; the parser cap is 387. The maximum
  result is 8,253: a true query needs two earlier insertions, so only positions
  3 through 128 can contribute.

## Bounded labeling profile

The source uses unsigned labels in a `2M` ring and folds cyclic differences
into the range `1..M`. This profile scales its half-ring parameter to
`M=2^31`, so labels are normalized on a `2^32` ring and the source's width
fold is retained. For anchor `x`, compute the positive cyclic width to its successor.
If the width exceeds one, assign the new node the midpoint label. Otherwise,
scan forward from `mid=next(x)` and `end=next(mid)` while
`width(x,end)<=4*width(x,mid)`, advancing `end` twice per iteration and
`mid` once. Set `required=3` initially and increase it once per advance. If
the scan wraps to `x`, use interval width `M`; otherwise use `width(x,end)`.
Walk backward from `end`, adding `M` when the walk crosses the sentinel and
assigning evenly spaced labels at the integer gap `interval//required`; label
additions wrap modulo `2M`. Then place the new node halfway after `x`, also
wrapping its label modulo `2M`.

The label state fits in signed 64-bit integers. At most 64 live nodes are
scanned or relabeled, so this bounded implementation takes `O(N)` time per
insert and `O(N)` space; each order query is `O(1)`. The primary reference uses
the label method. The independent reference stores the explicit list and
compares positions directly.

See the [workload](workload.json), [primary reference](primary_oracle.py),
[independent reference](independent_oracle.py), and
[static inventory](verify_workload.py).

## Source and rights

- Pinned source: [Spaghetti Source order maintenance](https://github.com/spaghetti-source/algorithm/blob/4fdac8202e26def25c1baf9127aaaed6a2c9f7c7/data_structure/order_maintenance.cc).
- The pinned repository [README](https://github.com/spaghetti-source/algorithm/blob/4fdac8202e26def25c1baf9127aaaed6a2c9f7c7/README.md) states that its code is public domain and may be used for any purpose without warranty.
- Dietz and Sleator, [“Two Algorithms for Maintaining Order in a List”](https://doi.org/10.1145/28395.28434), STOC 1987; [author-hosted paper](https://www.cs.cmu.edu/~sleator/papers/maintaining-order.pdf).

This benchmark uses algorithmic ideas only. Its implementations, oracles, and
fixtures are independently authored.

| Language | Port |
|---|---|
| C | [c/o/order_maintenance.c](../../../c/o/order_maintenance.c) |
| C3 | [c3/o/order_maintenance.c3](../../../c3/o/order_maintenance.c3) |
| C++ | [cpp/o/order_maintenance.cpp](../../../cpp/o/order_maintenance.cpp) |
| Elisa | [elisa/o/order_maintenance.elisa](../../../elisa/o/order_maintenance.elisa) |
| Mojo | [mojo/o/order_maintenance.mojo](../../../mojo/o/order_maintenance.mojo) |
| Nim | [nim/o/order_maintenance.nim](../../../nim/o/order_maintenance.nim) |
| Odin | [odin/o/order_maintenance.odin](../../../odin/o/order_maintenance.odin) |
| Rust | [rust/o/order_maintenance.rs](../../../rust/o/order_maintenance.rs) |
| V | [v/o/order_maintenance.v](../../../v/o/order_maintenance.v) |
| Zig | [zig/o/order_maintenance.zig](../../../zig/o/order_maintenance.zig) |
