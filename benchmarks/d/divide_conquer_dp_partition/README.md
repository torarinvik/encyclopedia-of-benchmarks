# Divide-and-conquer optimized partition DP

Partition a sequence of nonnegative values into exactly `k` nonempty
contiguous groups. The cost of a group is the square of its value sum; return
the minimum total group cost. This profile uses the divide-and-conquer
optimization for a layered DP whose leftmost optimal split indices are
monotone.

## Input and ABI

The exported scalar symbol is `divide_conquer_dp_partition` with ABI
`i64_array_scalar`. Input is `[n,k,value_0,...,value_(n-1)]`, where
`1<=n<=64`, `1<=k<=min(n,8)`, and every value is in `0..=1000`. The frame must
contain exactly `n+2` values. Invalid input returns `-1`. The maximum result is
`4,096,000,000`, reached when `k=1` and every value is 1000.

## Recurrence and method

Let `S[i]` be the prefix sum of the first `i` values. For group count `g` and
prefix length `i`,

```text
dp[g][i] = min over j in [g-1, i-1] of
           dp[g-1][j] + (S[i]-S[j])^2.
```

For nonnegative values, the squared segment-sum cost satisfies the
quadrangle inequality: for ordered boundaries `a<=b<=c<=d`, the difference
between the containing and crossed interval sums of squares is
`2*(S[b]-S[a])*(S[d]-S[c]) >= 0`. Adding the previous DP row preserves the
Monge ordering, so the leftmost optimal split is nondecreasing with `i`. Each
row therefore uses divide and conquer to search only the inherited split
intervals. The bounded implementation takes `O(k*n*log n)` candidate
evaluations and `O(n)` working storage.

The primary reference uses the same monotone-argmin divide-and-conquer method.
The independent reference scans every legal split in the full recurrence in
`O(k*n^2)` time. The implementation uses a deterministic leftmost-minimum tie
rule by updating only on strict improvement. See
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py).

This method differs from [`knuth_optimized_optimal_binary_search_tree`](../knuth_optimized_optimal_binary_search_tree/README.md),
which narrows interval-root candidates in an optimal-BST recurrence. It also
differs from convex-hull-trick DP, WQS, and CDQ divide and conquer: the cost is
not a line query, there is no penalty search, and the transitions do not cross
time halves.

## Source and rights

The method description is based on OI Wiki's
[Quadrangle Optimization](https://en.oi-wiki.org/dp/opt/quadrangle/)
chapter. OI Wiki content is under CC BY-SA 4.0 and SATA terms. This package
uses only the high-level algorithm description; the input contract, recurrence
instance, fixtures, references, and ports are clean-room work. See
[`RIGHTS.md`](RIGHTS.md) and [`workload.json`](workload.json).

## Ports

| Language | Source |
|---|---|
| C | [`c/d/divide_conquer_dp_partition.c`](../../../c/d/divide_conquer_dp_partition.c) |
| C3 | [`c3/d/divide_conquer_dp_partition.c3`](../../../c3/d/divide_conquer_dp_partition.c3) |
| C++ | [`cpp/d/divide_conquer_dp_partition.cpp`](../../../cpp/d/divide_conquer_dp_partition.cpp) |
| Elisa | [`elisa/d/divide_conquer_dp_partition.elisa`](../../../elisa/d/divide_conquer_dp_partition.elisa) |
| Mojo | [`mojo/d/divide_conquer_dp_partition.mojo`](../../../mojo/d/divide_conquer_dp_partition.mojo) |
| Nim | [`nim/d/divide_conquer_dp_partition.nim`](../../../nim/d/divide_conquer_dp_partition.nim) |
| Odin | [`odin/d/divide_conquer_dp_partition.odin`](../../../odin/d/divide_conquer_dp_partition.odin) |
| Rust | [`rust/d/divide_conquer_dp_partition.rs`](../../../rust/d/divide_conquer_dp_partition.rs) |
| V | [`v/d/divide_conquer_dp_partition.v`](../../../v/d/divide_conquer_dp_partition.v) |
| Zig | [`zig/d/divide_conquer_dp_partition.zig`](../../../zig/d/divide_conquer_dp_partition.zig) |

The workload includes small hand-computable cases, the maximum-size profile,
and malformed frames. The package-local static inventory checker is
[`check_inventory.py`](check_inventory.py); it has not been run.
