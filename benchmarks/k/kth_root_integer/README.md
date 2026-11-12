# Integer k-th Root

Return the largest integer `r` for which `r^K <= A`, for a nonnegative signed 64-bit integer `A` and degree `1 <= K <= 64`. The bounded local contract fits the scalar-array ABI and keeps the answer representable in signed 64-bit arithmetic.

## Contract

The `i64_array_scalar` ABI accepts exactly `[A, K]`. Valid inputs have `0 <= A <= 2^63-1` and `1 <= K <= 64`; invalid inputs return `-1`. This is a bounded form of the [Library Checker Kth Root (Integer) task](https://judge.yosupo.jp/problem/kth_root_integer), whose original `A` range is unsigned 64-bit.

The benchmark binary-searches `r` in `[0,A]`. To test a candidate without overflowing, it handles `r=0` directly, then multiplies one factor at a time and rejects before multiplying whenever the partial product exceeds `A / r`. The running time is `O(K log(A+1))` and the auxiliary space is `O(1)`.

See [`workload.json`](workload.json) for boundary cases and [`benchmarks/kth_root_integer_oracle.py`](../../kth_root_integer_oracle.py) for the independent arbitrary-precision oracle. The oracle uses Python's exact integer exponentiation rather than the ports' overflow-guarded multiplication.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kth_root_integer.c`](../../../c/k/kth_root_integer.c) |
| C3 | [`c3/k/kth_root_integer.c3`](../../../c3/k/kth_root_integer.c3) |
| C++ | [`cpp/k/kth_root_integer.cpp`](../../../cpp/k/kth_root_integer.cpp) |
| Elisa | [`elisa/k/kth_root_integer.elisa`](../../../elisa/k/kth_root_integer.elisa) |
| Mojo | [`mojo/k/kth_root_integer.mojo`](../../../mojo/k/kth_root_integer.mojo) |
| Nim | [`nim/k/kth_root_integer.nim`](../../../nim/k/kth_root_integer.nim) |
| Odin | [`odin/k/kth_root_integer.odin`](../../../odin/k/kth_root_integer.odin) |
| Rust | [`rust/k/kth_root_integer.rs`](../../../rust/k/kth_root_integer.rs) |
| V | [`v/k/kth_root_integer.v`](../../../v/k/kth_root_integer.v) |
| Zig | [`zig/k/kth_root_integer.zig`](../../../zig/k/kth_root_integer.zig) |
