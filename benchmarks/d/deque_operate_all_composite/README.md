# Deque Operate All Composite

This benchmark maintains an ordered deque of affine functions over the field
modulo 998244353. It supports insertion and removal at either end and queries
the composition of the full sequence. The profile uses an iterative segment
tree whose leaves follow the deque's logical order; each endpoint mutation
updates one root path, and the root stores the full composition.

The [Library Checker task](https://judge.yosupo.jp/problem/deque_operate_all_composite)
provides the operation semantics. Its repository is Apache-2.0 licensed; this
package uses only the task definition and algorithm taxonomy. The bounded
contract, ten implementation drafts, workload, and direct-list oracle are
independently written.

## Contract

Input is a packed signed 64-bit integer array `[Q, operations]`, with at most
64 operations. Each operation is:

- `0, a, b`: prepend `f(x) = a*x+b (mod 998244353)`.
- `1, a, b`: append the same affine function.
- `2`: remove the front function; this is invalid when the deque is empty.
- `3`: remove the back function; this is invalid when the deque is empty.
- `4, x`: apply the functions in front-to-back order to `x`. An empty deque
  returns `x`.

Multipliers satisfy `1 <= a < 998244353`; intercepts and query inputs lie in
`[0, 998244353)`. Invalid operation framing, values, or empty removals return
`-1`. The scalar result is the sum of `query_ordinal * (answer + 1)` for
one-based query ordinals. It remains within signed 64-bit range. The maximum
packed input length is 193 integers.

The deque occupies a centered 128-leaf sequence window in a fixed segment
tree. Because the total number of endpoint insertions is at most 64, all leaf
indices remain in range. A leaf update and tree recomputation take `O(log Q)`;
the root answers the aggregate in `O(1)`. Storage is fixed at `O(Q)` for the
bounded profile. Composition uses `compose(first, second) = second(first(x))`,
so left-to-right tree combination preserves the required noncommutative order.

## Workload and oracle

[`workload.json`](workload.json) covers empty identity queries, ordered
composition across both ends, both endpoint removals, malformed operations,
and invalid empty removals. The direct-list oracle applies every function in
order and is independent of the segment-tree implementation.

## Implementations

| Language | Source |
|---|---|
| C | [`c/d/deque_operate_all_composite.c`](../../../c/d/deque_operate_all_composite.c) |
| C3 | [`c3/d/deque_operate_all_composite.c3`](../../../c3/d/deque_operate_all_composite.c3) |
| C++ | [`cpp/d/deque_operate_all_composite.cpp`](../../../cpp/d/deque_operate_all_composite.cpp) |
| Elisa | [`elisa/d/deque_operate_all_composite.elisa`](../../../elisa/d/deque_operate_all_composite.elisa) |
| Mojo | [`mojo/d/deque_operate_all_composite.mojo`](../../../mojo/d/deque_operate_all_composite.mojo) (draft, unverified) |
| Nim | [`nim/d/deque_operate_all_composite.nim`](../../../nim/d/deque_operate_all_composite.nim) |
| Odin | [`odin/d/deque_operate_all_composite.odin`](../../../odin/d/deque_operate_all_composite.odin) |
| Rust | [`rust/d/deque_operate_all_composite.rs`](../../../rust/d/deque_operate_all_composite.rs) |
| V | [`v/d/deque_operate_all_composite.v`](../../../v/d/deque_operate_all_composite.v) |
| Zig | [`zig/d/deque_operate_all_composite.zig`](../../../zig/d/deque_operate_all_composite.zig) |
