# Mixed knapsack

This profile solves one knapsack instance containing a mixture of single-use,
unlimited, and bounded item types. Each type declares its own reuse mode. The
primary dispatches to the matching capacity-DP update direction and uses
binary grouping for finite bounded counts.

## Contract

The `i64_array_scalar` input is `[n,capacity,(mode,weight,value,limit)*n]`.
There are `0..16` item types, `0<=capacity<=64`, weights are `1..16`, and
values are `0..100`. A mode of `0` means 0/1 and requires `limit=1`; mode `1`
means unbounded and requires `limit=0`; mode `2` means bounded and accepts
`limit=0..16`. The marker values for modes 0 and 1 keep every record the same
width and are validated. There is no source of negative value, so selecting
nothing yields the valid result 0.

The frame must contain exactly `2+4*n` signed 64-bit values. At most 67 words
are parsed to reject trailing data; maximum valid and parseable lengths are
66 and 67 words. The return value is the maximum total value using at most the
capacity. Invalid or out-of-profile input returns `-1`; valid results are in
`0..6400`. Workspace is 1,024 bytes.

For a 0/1 type, the primary scans capacity downward once. For an unbounded
type, it scans upward so the current item can feed later capacities. For a
bounded type, it decomposes the copy limit into binary bundles and processes
each bundle with a descending 0/1 update. The work is
`O(C * (n + sum(log(k_i+1))))` for capacity `C`, with `O(C)` space.
The independent reference constructs a fresh DP row per type and directly
enumerates the allowed copy count, regardless of mode; it does not reuse the
primary's update-direction or binary-bundle kernels.

This package benchmarks one heterogeneous mode-dispatch operation. The local
[`knapsack_zero_one_tabulation`](../../k/knapsack_zero_one_tabulation/README.md),
[`unbounded_knapsack`](../../u/unbounded_knapsack/README.md),
[`bounded_knapsack_monotone_queue`](../../b/bounded_knapsack_monotone_queue/README.md),
and [`bounded_knapsack_binary_grouping`](../../b/bounded_knapsack_binary_grouping/README.md)
cover single-mode instances. Their transition kernels are reused here; this
profile does not claim those subalgorithms are new.

## Sources and files

Primary source: [CP-Algorithms, “Knapsack Problem,” Mixed Knapsack](https://cp-algorithms.com/dynamic_programming/knapsack.html#mixed-knapsack).
The source is used for algorithm discovery and description only. See
[`RIGHTS.md`](RIGHTS.md).

Hand-derived cases are in [`workload.json`](workload.json). The primary
reference is [`primary_oracle.py`](primary_oracle.py); the independent direct
copy-count DP is [`independent_oracle.py`](independent_oracle.py). Static
workload and port inventories are [`verify_workload.py`](verify_workload.py)
and [`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/mixed_knapsack.c`](../../../c/m/mixed_knapsack.c) |
| C3 | [`c3/m/mixed_knapsack.c3`](../../../c3/m/mixed_knapsack.c3) |
| C++ | [`cpp/m/mixed_knapsack.cpp`](../../../cpp/m/mixed_knapsack.cpp) |
| Elisa | [`elisa/m/mixed_knapsack.elisa`](../../../elisa/m/mixed_knapsack.elisa) |
| Mojo | [`mojo/m/mixed_knapsack.mojo`](../../../mojo/m/mixed_knapsack.mojo) |
| Nim | [`nim/m/mixed_knapsack.nim`](../../../nim/m/mixed_knapsack.nim) |
| Odin | [`odin/m/mixed_knapsack.odin`](../../../odin/m/mixed_knapsack.odin) |
| Rust | [`rust/m/mixed_knapsack.rs`](../../../rust/m/mixed_knapsack.rs) |
| V | [`v/m/mixed_knapsack.v`](../../../v/m/mixed_knapsack.v) |
| Zig | [`zig/m/mixed_knapsack.zig`](../../../zig/m/mixed_knapsack.zig) |

No programs, tests, scripts, checkers, builds, compilers, benchmarks, or
profilers were run while preparing this package.
