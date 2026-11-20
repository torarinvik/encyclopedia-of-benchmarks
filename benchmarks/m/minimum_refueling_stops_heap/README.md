# Minimum refueling stops with a max-heap

This package benchmarks the greedy minimum-refueling-stops algorithm: collect
the fuel of every reachable station, and whenever current reach must grow,
take the largest available fuel amount. The benchmark rebuilds its bounded
heap on each call.

## Contract

The ABI is `i64_array_scalar`; the package id and exported symbol are
`minimum_refueling_stops_heap`. Input is `[target, start_fuel, n,
position_0, fuel_0, ...]`, with stations in strictly increasing position
order. Bounds are `1<=target<=2000`, `0<=start_fuel<=2000`, `0<=n<=8`,
`1<=position_i<target`, and `1<=fuel_i<=2000`. The exact frame length is
`3+2*n`; no extra values are allowed. A station at the current reach is
reachable, and reaching the target with exactly zero fuel counts as arrival.

The scalar result is the minimum stop count, or `-1` when the route is
unreachable. Invalid and null frames return `-2`, keeping invalid input
distinct from a valid but impossible trip. The heap can hold at most eight
station amounts. Maximum valid input length is 19 values; implementations
accept up to one extra parseable value to reject trailing data explicitly.

## Algorithm and distinction

The scan advances the reachable distance without committing to a station
choice. At each step it inserts all stations whose positions are within the
current reach. If the target is still beyond reach, it removes the largest
fuel amount from that max-heap and extends reach by that amount. An empty heap
before reaching the target proves the route impossible. This exchange-based
greedy choice minimizes the number of selected stations; the bounded
implementation takes `O(n log n)` time and `O(n)` space.

The nearby local `gas_station` benchmark solves a different circular-route
problem: it finds a starting index from which gas supply can cover the
gas-cost circuit. This package models a one-way route with a destination and
minimizes the number of selected refueling stops. The primary oracle uses the
greedy max-heap; the independent oracle uses descending dynamic programming
over stop counts and does not use a heap.

## Source and ports

The problem semantics and editorial reference are from the official
[LeetCode 871 statement](https://leetcode.com/problems/minimum-number-of-refueling-stops/)
and its [editorial](https://leetcode.com/problems/minimum-number-of-refueling-stops/editorial/).
Only the algorithm idea and problem semantics are used. The code is
clean-room, and no LeetCode or other third-party code is copied. See
[`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/m/minimum_refueling_stops_heap.c`](../../../c/m/minimum_refueling_stops_heap.c) |
| C3 | [`c3/m/minimum_refueling_stops_heap.c3`](../../../c3/m/minimum_refueling_stops_heap.c3) |
| C++ | [`cpp/m/minimum_refueling_stops_heap.cpp`](../../../cpp/m/minimum_refueling_stops_heap.cpp) |
| Elisa | [`elisa/m/minimum_refueling_stops_heap.elisa`](../../../elisa/m/minimum_refueling_stops_heap.elisa) |
| Mojo | [`mojo/m/minimum_refueling_stops_heap.mojo`](../../../mojo/m/minimum_refueling_stops_heap.mojo) |
| Nim | [`nim/m/minimum_refueling_stops_heap.nim`](../../../nim/m/minimum_refueling_stops_heap.nim) |
| Odin | [`odin/m/minimum_refueling_stops_heap.odin`](../../../odin/m/minimum_refueling_stops_heap.odin) |
| Rust | [`rust/m/minimum_refueling_stops_heap.rs`](../../../rust/m/minimum_refueling_stops_heap.rs) |
| V | [`v/m/minimum_refueling_stops_heap.v`](../../../v/m/minimum_refueling_stops_heap.v) |
| Zig | [`zig/m/minimum_refueling_stops_heap.zig`](../../../zig/m/minimum_refueling_stops_heap.zig) |

[`workload.json`](workload.json) covers a multi-stop contraction, exact fuel
arrival, no-stop and impossible routes, the maximum station count, and invalid
frames. [`verify_workload.py`](verify_workload.py) provides static fixture and
source-inventory review; it has not been run as part of this package work.
