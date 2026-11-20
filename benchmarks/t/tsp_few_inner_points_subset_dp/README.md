# TSP with few inner points: subset dynamic programming

This package implements the second fixed parameter algorithm in Chapter 426.
It fixes the supplied cyclic order of hull points and evaluates the paper's
`F2[i,S,r]` dynamic program over subsets of interior points. It completes the
written recurrence's apparent missing `i=1` case by seeding the first hull
layer and applying the inner-point transition there, so interior points may
also lie in the first hull gap. The implementation rolls the outer-prefix
dimension, keeping `O(2^k k)` DP storage. It differs from
[`tsp_few_inner_points`](../tsp_few_inner_points/README.md), which enumerates
all interior-point orders and runs the lower-space two-endpoint DP for each.

## Contract

- ABI and symbol: `i64_array_bytes_output`,
  `tsp_few_inner_points_subset_dp`.
- Input is `[n,k,outer_ids...,inner_ids...,x0,y0,...]`. The caller supplies the
  strict convex-hull cycle and the remaining strictly interior points, as
  assumed by the source algorithm. Bounds are `3<=n<=16`,
  `0<=k<=min(6,n-3)`, distinct point IDs, and distinct coordinates in
  `[-1000,1000]`. The valid length is `2+3*n`; a trailing word is parseable so
  it can be rejected with `-1`.
- The objective is the minimum fixed-point cost among tours that preserve the
  supplied hull cycle. Each Euclidean edge is rounded to the nearest thousandth,
  with exact ties rounded down, and the costs are summed as integers. Output is
  one little-endian i64 cost in thousandths. This bounded rounded-metric hull-
  order profile does not claim the unrestricted exact-Euclidean optimum.
- Invalid input returns `-1`. Null or short output returns `-2` without
  writing. The maximum output is eight bytes.

For `k` interior points, the subset recurrence takes `O(2^k k^2 n)` time.
Rolling over hull prefixes uses `O(2^k k)` DP storage; the bounded workspace
is 8192 bytes in the portable ports.

The primary reference implements §4's subset DP. The independent reference
uses the distinct §3 permutation enumeration and two-endpoint DP. Both use the
same explicit fixed-point metric and input contract.

## Source and rights

Deıneko, Hoffmann, Okamoto, and Woeginger, “The Traveling Salesman Problem
with Few Inner Points,” §4, [primary paper](https://dopal.cs.uec.ac.jp/okamotoy/PDF/2006/FINALfewTSP.pdf).
The chapter is [DOI 10.1007/978-1-4939-2864-4_426](https://doi.org/10.1007/978-1-4939-2864-4_426).
This package uses the algorithm description only; it does not reproduce
source code, prose, figures, or test data. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/tsp_few_inner_points_subset_dp.c`](../../../c/t/tsp_few_inner_points_subset_dp.c) |
| C3 | [`c3/t/tsp_few_inner_points_subset_dp.c3`](../../../c3/t/tsp_few_inner_points_subset_dp.c3) |
| C++ | [`cpp/t/tsp_few_inner_points_subset_dp.cpp`](../../../cpp/t/tsp_few_inner_points_subset_dp.cpp) |
| Elisa | [`elisa/t/tsp_few_inner_points_subset_dp.elisa`](../../../elisa/t/tsp_few_inner_points_subset_dp.elisa) |
| Mojo | [`mojo/t/tsp_few_inner_points_subset_dp.mojo`](../../../mojo/t/tsp_few_inner_points_subset_dp.mojo) |
| Nim | [`nim/t/tsp_few_inner_points_subset_dp.nim`](../../../nim/t/tsp_few_inner_points_subset_dp.nim) |
| Odin | [`odin/t/tsp_few_inner_points_subset_dp.odin`](../../../odin/t/tsp_few_inner_points_subset_dp.odin) |
| Rust | [`rust/t/tsp_few_inner_points_subset_dp.rs`](../../../rust/t/tsp_few_inner_points_subset_dp.rs) |
| V | [`v/t/tsp_few_inner_points_subset_dp.v`](../../../v/t/tsp_few_inner_points_subset_dp.v) |
| Zig | [`zig/t/tsp_few_inner_points_subset_dp.zig`](../../../zig/t/tsp_few_inner_points_subset_dp.zig) |

See [workload.json](workload.json), the two references, and the static
inventory [verify_workload.py](verify_workload.py).
