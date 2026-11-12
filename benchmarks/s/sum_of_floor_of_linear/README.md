# Sum of Floor of Linear

For nonnegative integers `N`, `M`, `A`, and `B`, compute `sum(floor((A*i+B)/M))` for `i` from 0 through `N-1`. The implementation uses the Euclidean floor-sum recurrence, reducing the modulus and slope until the remaining lattice-point count is zero. This is a distinct number-theory algorithm, not a repeated linear scan.

## Contract

The `i64_array_scalar` ABI accepts exactly `[N, M, A, B]` and returns the exact sum as a signed 64-bit integer. The contract follows the [Library Checker task](https://judge.yosupo.jp/problem/sum_of_floor_of_linear): `1 <= N,M <= 1,000,000,000` and `0 <= A,B < M`. Invalid input returns `-1`. These bounds keep the answer at or below `N*(N-1)/2`, which is at most `499,999,999,500,000,000`.

The online judge batches `T` cases; this benchmark sends one tuple per ABI call, leaving text parsing and batch framing outside the algorithm. The recurrence takes `O(log M)` time and `O(1)` extra space, as documented for [`floor_sum` in AtCoder Library](https://atcoder.github.io/ac-library/master/document_en/math.html).

See [`workload.json`](workload.json) for representative cases and [`benchmarks/sum_of_floor_of_linear_oracle.py`](../../sum_of_floor_of_linear_oracle.py) for the recursive Euclidean reference oracle. Implementations are clean-room ports from the task contract and the classical floor-sum recurrence.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_floor_of_linear.c`](../../../c/s/sum_of_floor_of_linear.c) |
| C3 | [`c3/s/sum_of_floor_of_linear.c3`](../../../c3/s/sum_of_floor_of_linear.c3) |
| C++ | [`cpp/s/sum_of_floor_of_linear.cpp`](../../../cpp/s/sum_of_floor_of_linear.cpp) |
| Elisa | [`elisa/s/sum_of_floor_of_linear.elisa`](../../../elisa/s/sum_of_floor_of_linear.elisa) |
| Mojo | [`mojo/s/sum_of_floor_of_linear.mojo`](../../../mojo/s/sum_of_floor_of_linear.mojo) |
| Nim | [`nim/s/sum_of_floor_of_linear.nim`](../../../nim/s/sum_of_floor_of_linear.nim) |
| Odin | [`odin/s/sum_of_floor_of_linear.odin`](../../../odin/s/sum_of_floor_of_linear.odin) |
| Rust | [`rust/s/sum_of_floor_of_linear.rs`](../../../rust/s/sum_of_floor_of_linear.rs) |
| V | [`v/s/sum_of_floor_of_linear.v`](../../../v/s/sum_of_floor_of_linear.v) |
| Zig | [`zig/s/sum_of_floor_of_linear.zig`](../../../zig/s/sum_of_floor_of_linear.zig) |
