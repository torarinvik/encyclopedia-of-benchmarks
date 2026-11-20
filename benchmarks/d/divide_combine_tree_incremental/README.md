# Incremental Divide-and-Combine Tree

This profile builds the primitive-segment tree of a bounded permutation with
the incremental Divide-and-Combine method. It is a construction variant of
[`common_interval_decomposition_tree`](../../c/common_interval_decomposition_tree/README.md):
both identify the same strong connected intervals, while that package uses
exhaustive interval and overlap checks and this one uses a range-minimum tree,
monotone extrema stacks, and a tree-node stack.

## Contract

- ABI: `i64_array_scalar`.
- Input: `[n, P_0, ..., P_(n-1)]`, with `1 <= n <= 16` and `P` a permutation
  of `0..n-1`. The exact length is `n+1`; the maximum valid length is 17 i64
  values and the maximum parseable length is 18.
- Malformed or null input returns `-1`.
- A connected interval `[left,right]` has
  `max(P[left..right]) - min(P[left..right]) == right-left`.
- The checksum uses nonempty positional intervals. (OI Wiki's formal family
  also mentions the empty set; it has no inclusive positional endpoints and is
  omitted from this scalar profile.)
- A primitive segment is a connected interval that overlaps no connected
  interval without containing it or being contained by it. Singleton
  intervals and the full permutation interval are included.
- The construction processes the permutation from left to right. A lazy
  range-add/range-min segment tree tracks the range-minus-width quantity for
  every possible start. Monotone minimum and maximum stacks batch updates;
  the leftmost zero locates the earliest connected suffix. A stack of tree
  nodes then extends combine nodes or merges nodes into a combine/divide node.
- Sort the resulting primitive intervals by `(left,right)` in ascending
  order, using inclusive zero-based endpoints. Number them `t=1..m`, then
  return `sum(t * ((left+1)*(n+1) + (right+1)))`. Since `m <= 2n-1`, the result
  is at most 142,848 and fits signed 64-bit.
- The bounded construction takes `O(n log n)` time and `O(n)` workspace. The
  segment tree handles each monotone-stack range update in `O(log n)`; each
  position enters and leaves each extrema stack at most once.

## Independent references

[`primary_oracle.py`](primary_oracle.py) mirrors the incremental segment-tree,
monotone-stack, and node-stack construction. [`independent_oracle.py`](independent_oracle.py)
enumerates connected intervals by explicit value sets and filters strong
intervals with pairwise overlap checks. Both compute the specified checksum.
[`workload.json`](workload.json) records valid, malformed, and profile inputs;
[`verify_workload.py`](verify_workload.py) provides static metadata and
dual-reference checks and was not run.

The ten ports are in `c/d`, `c3/d`, `cpp/d`, `elisa/d`, `mojo/d`, `nim/d`,
`odin/d`, `rust/d`, `v/d`, and `zig/d`.

## Provenance

The construction method is described in [OI Wiki: Divide and Combine
Tree](https://www.timothywang.ca/OI-wiki/ds/divide-combine/), including its
incremental `O(n log n)` approach and the range-minimum/monotone-stack updates.
The algorithm description is used as a source of ideas only. The bounded
contract, checksum, references, workload, documentation, and ports are written
independently. See [`RIGHTS.md`](RIGHTS.md).
