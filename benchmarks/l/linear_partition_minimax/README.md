# Linear partition minimax

Partition a sequence of nonnegative values into exactly `m` nonempty contiguous
groups, minimizing the largest group sum. Group order follows input order.

## Contract

The `i64_array_scalar` input is `[n,m,value_0,...,value_(n-1)]`, with
`1<=n<=32`, `1<=m<=n`, and each value in `[0,1000]`. The exact input length is
`n+2`; the maximum valid length is 34 and the maximum parseable length is 35,
so a single trailing-word probe is rejected. Return the minimum possible
largest group sum, in `[0,32000]`. Null, malformed, or out-of-domain input
returns `-1`.

The primary ports binary-search the answer between the largest item and the
total sum. For a candidate limit, a greedy left-to-right scan starts a new
group only when adding the next item would exceed the limit. The limit is
feasible when this uses at most `m` groups. Since all values are nonnegative
and `n>=m`, any feasible partition with fewer groups can be split until it has
exactly `m` nonempty groups without increasing its largest sum. The primary
uses `O(n log(sum(values)+1))` time and `O(1)` extra space.

The independent reference uses cut-point dynamic programming. For a prefix of
length `i` split into `g` groups, it minimizes over the last cut `j` the larger
of the best `g-1` group cost on the prefix through `j` and the sum of the final
group. This takes `O(m n^2)` time and `O(n)` rolling-row space.

## Sources and provenance

Skiena’s [linear partition lecture](https://www3.cs.stonybrook.edu/~skiena/373/current-lectures/lecture18.pdf)
states the ordered partition objective for nonnegative values and gives the
cut-point dynamic-programming recurrence and `O(m n^2)` bound. His *The
Algorithm Design Manual*, section 10.7, gives the same ordered-partition
discussion ([public copy](https://users.math.uoc.gr/~plex/mem291-Fall2023/ark/Skiena-The_Algorithm_Design_Manual.pdf)).
The public LeetCode [title/topic index](https://leetcode.com/problem-list/dynamic-programming/)
was used for discovery only. The package uses the mathematical operation and
independently written algorithms; no task statement, example, test, submission,
or code is reused. See [RIGHTS.md](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) covers the single-group and one-item bounds,
exactly `n` groups, zero values, nontrivial optima, maximum dimensions,
malformed framing, and domain errors. The primary and independent references
are `primary_oracle.py` and `independent_oracle.py`. A source inventory is
listed in [`INVENTORY.md`](INVENTORY.md); [`check_inventory.py`](check_inventory.py)
is a static file/provenance review helper and has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/linear_partition_minimax.c`](../../../c/l/linear_partition_minimax.c) |
| C3 | [`c3/l/linear_partition_minimax.c3`](../../../c3/l/linear_partition_minimax.c3) |
| C++ | [`cpp/l/linear_partition_minimax.cpp`](../../../cpp/l/linear_partition_minimax.cpp) |
| Elisa | [`elisa/l/linear_partition_minimax.elisa`](../../../elisa/l/linear_partition_minimax.elisa) |
| Mojo | [`mojo/l/linear_partition_minimax.mojo`](../../../mojo/l/linear_partition_minimax.mojo) |
| Nim | [`nim/l/linear_partition_minimax.nim`](../../../nim/l/linear_partition_minimax.nim) |
| Odin | [`odin/l/linear_partition_minimax.odin`](../../../odin/l/linear_partition_minimax.odin) |
| Rust | [`rust/l/linear_partition_minimax.rs`](../../../rust/l/linear_partition_minimax.rs) |
| V | [`v/l/linear_partition_minimax.v`](../../../v/l/linear_partition_minimax.v) |
| Zig | [`zig/l/linear_partition_minimax.zig`](../../../zig/l/linear_partition_minimax.zig) |
