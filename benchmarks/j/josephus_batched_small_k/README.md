# Batched small-step Josephus recurrence

This benchmark computes the zero-based survivor for a circle of `N` participants and elimination step `K`. It uses the batched recurrence documented by OI Wiki: when `K <= N`, remove `floor(N/K)` complete sweeps at once, solve the smaller circle, and map the survivor back. When `K > N`, the recurrence reduces by one participant at a time. The recurrence is unwound iteratively using a bounded local frame array.

## Contract

- ABI: `i64_array_scalar`; symbol: `josephus_batched_small_k`.
- Input is exactly `[N,K]`; `1 <= N <= 1,000,000` and `1 <= K <= 32`.
- Participants use zero-based indices and counting begins at index zero. Return the surviving index in `[0,N)`; malformed or out-of-range input returns `-1`.
- The primary algorithm pushes each reduced circle size, then applies the inverse mapping while unwinding. For frame size `m >= K`, subtract `m mod K`; add `m` if this is negative, otherwise add `floor(r/(K-1))`. For `m < K`, the child is `m-1` and the inverse is `(r+K) mod m`.
- Time is `O(K log N)` in the bounded small-`K` regime and the fixed frame stack has 1,024 i64 entries (8,192 bytes). The stack depth stays below 1,024: for `n >= 64`, each batched reduction removes at least `floor(n/32) >= n/64`; each block of 64 such reductions shrinks `n` by a factor below one half. At most 14 such blocks take `N <= 10^6` below 64, followed by fewer than 64 one-step reductions. Including scalar locals, the declared workspace cap is 16,384 bytes.
- The independent reference applies the one-size Josephus recurrence in `O(N)` time; a list-elimination simulator is included for tiny inputs.

## Source and distinction

The algorithmic recurrence is described at [OI Wiki, Josephus problem](https://en.oi-wiki.org/misc/josephus/). The source is used for the mathematical recurrence only; ports and fixtures here are clean-room. Existing `josephus_problem` and `josephus_problem_recursive` packages apply the one-size recurrence at every circle size, while `josephus_problem_simulation` removes participants individually. This profile batches complete sweeps and has a distinct small-`K` complexity and implementation strategy.

## Workload and inventory

`workload.json` pins valid and invalid input cases and their scalar outputs. `primary_oracle.py` expresses the batched method; `independent_oracle.py` provides the direct linear recurrence and tiny list simulation. `verify_workload.py` and `check_inventory.py` are static artifacts and were not executed.

## Ports

- [C](../../../c/j/josephus_batched_small_k.c)
- [C3](../../../c3/j/josephus_batched_small_k.c3)
- [C++](../../../cpp/j/josephus_batched_small_k.cpp)
- [Elisa](../../../elisa/j/josephus_batched_small_k.elisa)
- [Mojo](../../../mojo/j/josephus_batched_small_k.mojo)
- [Nim](../../../nim/j/josephus_batched_small_k.nim)
- [Odin](../../../odin/j/josephus_batched_small_k.odin)
- [Rust](../../../rust/j/josephus_batched_small_k.rs)
- [V](../../../v/j/josephus_batched_small_k.v)
- [Zig](../../../zig/j/josephus_batched_small_k.zig)
