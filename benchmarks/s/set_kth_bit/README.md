# Set the kth bit

Set the zero-based bit position `k` in the nonnegative integer `N` and return the resulting integer. The contract keeps the upstream C++ mask expression `1 << k` within its defined signed `int` range.

## Contract

The `i64_array_scalar` input is exactly `[N, k]`. `N` is in `[0, 2^31 - 1]` and `k` is in `[0, 30]`. The result is `N | (1 << k)`, with the least significant bit at position zero. Invalid shape or values return `-1`.

## Workload

[`workload.json`](workload.json) covers setting clear bits, preserving already-set bits, the highest allowed position, maximum input, and malformed or out-of-domain inputs.
The shared scalar runner now checks the source-safe bit-set operation for this contract.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms set_kth_bit --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/set_kth_bit.c`](../../../c/s/set_kth_bit.c) |
| C3 | [`c3/s/set_kth_bit.c3`](../../../c3/s/set_kth_bit.c3) |
| C++ | [`cpp/s/set_kth_bit.cpp`](../../../cpp/s/set_kth_bit.cpp) |
| Elisa | [`elisa/s/set_kth_bit.elisa`](../../../elisa/s/set_kth_bit.elisa) |
| Nim | [`nim/s/set_kth_bit.nim`](../../../nim/s/set_kth_bit.nim) |
| Odin | [`odin/s/set_kth_bit.odin`](../../../odin/s/set_kth_bit.odin) |
| Rust | [`rust/s/set_kth_bit.rs`](../../../rust/s/set_kth_bit.rs) |
| V | [`v/s/set_kth_bit.v`](../../../v/s/set_kth_bit.v) |
| Zig | [`zig/s/set_kth_bit.zig`](../../../zig/s/set_kth_bit.zig) |

## Pinned sources

- C++ [`set_kth_bit.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/set_kth_bit.cpp)
- C++-1 [`set_kth_bit.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/bit_manipulation/set_kth_bit.cpp)

Both sources set the requested bit by ORing `N` with `1 << k`. The bounded contract excludes negative values and positions that could overflow the source's signed shift.
