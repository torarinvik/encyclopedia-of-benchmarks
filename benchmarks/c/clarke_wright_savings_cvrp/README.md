# Parallel Clarke–Wright savings for capacitated vehicle routing

This package implements the parallel Clarke–Wright savings heuristic for a
small homogeneous-capacity vehicle-routing instance. It begins with one route
per customer, sorts each customer-pair saving once, and joins two different
routes only when the selected customers are exposed route ends and the merged
load fits the vehicle capacity.

## Contract

- ABI and exported symbol: `i64_array_bytes_output`,
  `clarke_wright_savings_cvrp`.
- Input words are `[n, capacity, demands[1..n], distances[0..n,0..n]]` with
  depot ID 0 and customer IDs 1 through `n`. The complete row-major distance
  matrix is symmetric, has a zero diagonal, and contains nonnegative integer
  distances at most 1000. Demands are positive integers no larger than the
  capacity, and capacity is in `1..100`. The bound is `0<=n<=7`.
- Savings are `d(0,i)+d(0,j)-d(i,j)` for `i<j`. The profile sorts pairs by
  decreasing saving, then ascending `(i,j)`, processes each pair once, and
  accepts merges only when saving is strictly positive. Zero and negative
  savings are skipped. A merge orients the route chains so the selected pair
  becomes adjacent as `i→j`.
- Completed routes are oriented as the lexicographically smaller of each
  route and its reversal, then the route list is sorted lexicographically.
  Depot visits are implicit. Output words are `[route_count, len_1, customers…,
  len_2, customers…]`, encoded as little-endian signed i64 values. The maximum
  output is 120 bytes. This is a deterministic heuristic profile; it makes no
  optimality claim.
- Invalid input returns `-1`. Null or insufficient output returns `-2` without
  writing. Input may contain one trailing parseable word, which is rejected.

The primary reference uses explicit route chains. The independent reference
uses a customer adjacency forest, discovers components and endpoints after
each accepted join, and reconstructs paths before canonical serialization.
The workload includes a maximum-size seven-customer case whose capacity blocks
all merges, exercising the 120-byte route output bound.

## Source and rights

G. Clarke and J. W. Wright, “Scheduling of Vehicles from a Central Depot to a
Number of Delivery Points,” *Operations Research* 12(4), 568–581 (1964),
[DOI 10.1287/opre.12.4.568](https://doi.org/10.1287/opre.12.4.568). The ports
use the algorithm description only; no paper text, code, figures, or test data
are reproduced. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/clarke_wright_savings_cvrp.c`](../../../c/c/clarke_wright_savings_cvrp.c) |
| C3 | [`c3/c/clarke_wright_savings_cvrp.c3`](../../../c3/c/clarke_wright_savings_cvrp.c3) |
| C++ | [`cpp/c/clarke_wright_savings_cvrp.cpp`](../../../cpp/c/clarke_wright_savings_cvrp.cpp) |
| Elisa | [`elisa/c/clarke_wright_savings_cvrp.elisa`](../../../elisa/c/clarke_wright_savings_cvrp.elisa) |
| Mojo | [`mojo/c/clarke_wright_savings_cvrp.mojo`](../../../mojo/c/clarke_wright_savings_cvrp.mojo) |
| Nim | [`nim/c/clarke_wright_savings_cvrp.nim`](../../../nim/c/clarke_wright_savings_cvrp.nim) |
| Odin | [`odin/c/clarke_wright_savings_cvrp.odin`](../../../odin/c/clarke_wright_savings_cvrp.odin) |
| Rust | [`rust/c/clarke_wright_savings_cvrp.rs`](../../../rust/c/clarke_wright_savings_cvrp.rs) |
| V | [`v/c/clarke_wright_savings_cvrp.v`](../../../v/c/clarke_wright_savings_cvrp.v) |
| Zig | [`zig/c/clarke_wright_savings_cvrp.zig`](../../../zig/c/clarke_wright_savings_cvrp.zig) |

See the [workload](workload.json), [primary reference](primary_oracle.py), and
[independent reference](independent_oracle.py).
