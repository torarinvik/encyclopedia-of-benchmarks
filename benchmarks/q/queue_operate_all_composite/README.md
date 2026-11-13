# Queue Operate All Composite

This benchmark measures a FIFO queue of affine functions with aggregate queries over the complete queue. It uses the two-stack aggregation method: each stack stores the composition of its elements, and transferring between stacks reverses the queue order while rebuilding aggregates.

The task semantics come from [Library Checker: Queue Operate All Composite](https://judge.yosupo.jp/problem/queue_operate_all_composite) and its [proposal](https://github.com/yosupo06/library-checker-problems/issues/208). These sources are used as algorithm references only. The bounded contract, implementations, workload, and independent direct-list oracle are written for this repository; no problem statement or submitted source code is copied.

## Contract

Input is a packed signed 64-bit integer array. Its first value is the operation count, limited to 64. Each operation is one of:

- `0, a, b`: append the function `f(x) = a*x+b (mod 998244353)`; `1 <= a < 998244353` and `0 <= b < 998244353`.
- `1`: remove the oldest function; removing from an empty queue is invalid.
- `2, x`: apply every queued function from oldest to newest to `x`; `0 <= x < 998244353`. An empty queue returns `x`.

The scalar result is the sum of `query_ordinal * (answer + 1)`, using one-based query ordinals. At most 64 operations are accepted, so the packed input is at most 193 values. Invalid framing or values return `-1`; no queries return `0`.

Each push and aggregate query takes `O(1)` amortized time. A pop takes `O(1)` amortized time because each function moves between stacks at most once. Storage is `O(Q)` for `Q <= 64` operations. Affine composition is ordered and noncommutative; the front and back aggregates are combined in queue order.

## Workload and implementations

The workload includes empty-queue identity queries, composition order, FIFO removal, modular arithmetic, malformed traces, and null input. The package checker compares its fixtures against a direct-list oracle and checks that all ten language sources and provenance links are present. The benchmark uses the `i64_array_scalar` ABI.

| Language | Source |
| --- | --- |
| C | [c/q/queue_operate_all_composite.c](../../../c/q/queue_operate_all_composite.c) |
| C3 | [c3/q/queue_operate_all_composite.c3](../../../c3/q/queue_operate_all_composite.c3) |
| C++ | [cpp/q/queue_operate_all_composite.cpp](../../../cpp/q/queue_operate_all_composite.cpp) |
| Elisa | [elisa/q/queue_operate_all_composite.elisa](../../../elisa/q/queue_operate_all_composite.elisa) |
| Mojo | [mojo/q/queue_operate_all_composite.mojo](../../../mojo/q/queue_operate_all_composite.mojo) (draft, unverified) |
| Nim | [nim/q/queue_operate_all_composite.nim](../../../nim/q/queue_operate_all_composite.nim) |
| Odin | [odin/q/queue_operate_all_composite.odin](../../../odin/q/queue_operate_all_composite.odin) |
| Rust | [rust/q/queue_operate_all_composite.rs](../../../rust/q/queue_operate_all_composite.rs) |
| V | [v/q/queue_operate_all_composite.v](../../../v/q/queue_operate_all_composite.v) |
| Zig | [zig/q/queue_operate_all_composite.zig](../../../zig/q/queue_operate_all_composite.zig) |
