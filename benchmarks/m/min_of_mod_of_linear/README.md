# Minimum of Modulo of a Linear Sequence

Compute `min((A*x+B) mod M)` for integer `x` in `[0,N)`. The bounded implementation binary-searches the smallest residue threshold and uses a Euclidean floor-sum to count whether any term is at or below that threshold. This handles ranges too large for a direct scan and works when `A` and `M` are not coprime.

## Contract

The `i64_array_scalar` ABI accepts exactly `[N, M, A, B]` and returns the minimum residue as a signed 64-bit integer. The contract follows the [Library Checker task](https://judge.yosupo.jp/problem/min_of_mod_of_linear): `1 <= N,M <= 1,000,000,000` and `0 <= A,B < M`. Invalid input returns `-1`; valid results are in `[0,M-1]`. The online task batches `T` cases, while this benchmark sends one tuple per call and leaves parsing outside the algorithm.

For a candidate `k`, add `M-1-k` to each numerator. The shifted floor increases by one exactly when the original residue exceeds `k`; therefore the number of residues at most `k` is positive exactly when
`floor_sum(N,M,A,B+M-1-k) < floor_sum(N,M,A,B)+N`.
Binary search over `k` uses `O(log M)` floor-sum queries, each taking `O(log M)`, for `O(log² M)` time and `O(1)` extra space.

See [`workload.json`](workload.json) for representative cases and [`benchmarks/min_of_mod_of_linear_oracle.py`](../../min_of_mod_of_linear_oracle.py) for a reference oracle. The threshold criterion is described in this [CP-library algorithm note](https://suisen-cp.github.io/cp-library-cpp/library/number/min_of_mod_of_linear.hpp); these ports are independently written from the mathematical criterion and task contract.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/min_of_mod_of_linear.c`](../../../c/m/min_of_mod_of_linear.c) |
| C3 | [`c3/m/min_of_mod_of_linear.c3`](../../../c3/m/min_of_mod_of_linear.c3) |
| C++ | [`cpp/m/min_of_mod_of_linear.cpp`](../../../cpp/m/min_of_mod_of_linear.cpp) |
| Elisa | [`elisa/m/min_of_mod_of_linear.elisa`](../../../elisa/m/min_of_mod_of_linear.elisa) |
| Mojo | [`mojo/m/min_of_mod_of_linear.mojo`](../../../mojo/m/min_of_mod_of_linear.mojo) |
| Nim | [`nim/m/min_of_mod_of_linear.nim`](../../../nim/m/min_of_mod_of_linear.nim) |
| Odin | [`odin/m/min_of_mod_of_linear.odin`](../../../odin/m/min_of_mod_of_linear.odin) |
| Rust | [`rust/m/min_of_mod_of_linear.rs`](../../../rust/m/min_of_mod_of_linear.rs) |
| V | [`v/m/min_of_mod_of_linear.v`](../../../v/m/min_of_mod_of_linear.v) |
| Zig | [`zig/m/min_of_mod_of_linear.zig`](../../../zig/m/min_of_mod_of_linear.zig) |
