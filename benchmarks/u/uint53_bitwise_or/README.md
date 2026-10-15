# uint53 bitwise OR

Compute the inclusive bitwise OR of two unsigned integers in the range supported
by Lua's `uint53` modules.

## Contract

- Inputs use the `binary_scalar` ABI as two unsigned 64-bit values `[left, right]`.
- Each input must be in `0..=2^53-1` (`0..=9,007,199,254,740,991`).
- Return `left OR right` as a nonnegative signed 64-bit integer. Inputs outside
  the uint53 range return `-1`.
- The output stays within the uint53 range, so the invalid sentinel cannot be a
  valid result.

The pinned Lua function extracts each least-significant bit, accumulates the OR
bit by bit, then appends the remaining bits once either operand reaches zero.
The ports preserve that arithmetic algorithm. They use a two-condition loop
instead of multiplying the operands to test whether both are nonzero, avoiding
fixed-width multiplication overflow. The benchmark adds range checks; the Lua
source documents the expected `uint53` inputs but does not validate them.

## Workload and build

[`workload.json`](workload.json) covers zero, individual bits, overlapping and
disjoint bits, the maximum uint53 value, and out-of-range inputs.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm uint53_bitwise_or --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/u/uint53_bitwise_or/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/uint53_bitwise_or.c`](../../../c/u/uint53_bitwise_or.c) |
| C3 | [`c3/b/uint53_bitwise_or.c3`](../../../c3/u/uint53_bitwise_or.c3) |
| C++ | [`cpp/b/uint53_bitwise_or.cpp`](../../../cpp/u/uint53_bitwise_or.cpp) |
| Elisa | [`elisa/b/uint53_bitwise_or.elisa`](../../../elisa/u/uint53_bitwise_or.elisa) |
| Nim | [`nim/b/uint53_bitwise_or.nim`](../../../nim/u/uint53_bitwise_or.nim) |
| Odin | [`odin/b/uint53_bitwise_or.odin`](../../../odin/u/uint53_bitwise_or.odin) |
| Rust | [`rust/b/uint53_bitwise_or.rs`](../../../rust/u/uint53_bitwise_or.rs) |
| V | [`v/b/uint53_bitwise_or.v`](../../../v/u/uint53_bitwise_or.v) |
| Zig | [`zig/b/uint53_bitwise_or.zig`](../../../zig/u/uint53_bitwise_or.zig) |

## TheAlgorithms reference

- [Lua `or.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/or.lua)
