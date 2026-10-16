# uint53 bitwise XOR

Compute the bitwise exclusive OR of two exact nonnegative integers. This benchmark represents the standalone numeric algorithm in the pinned Lua source; it is separate from the Go and Rust `xor` files, which implement a bytewise XOR cipher.

## Contract

- Inputs are two signed-i64 values in `[0, 2^53 - 1]`, the exact integer range used by the Lua `uint53` module.
- Return `left XOR right`. Inputs outside the range return `-1`.
- The implementation follows the source's bit-by-bit decomposition and recombination loop.

The C ABI is `int64_t uint53_xor(int64_t left, int64_t right);`.

## Workload and verification

[`workload.json`](workload.json) covers zero, identical values, individual and alternating bits, the largest accepted operand, malformed signed values, and seeded random pairs. [`benchmarks/uint53_xor_oracle.py`](../../uint53_xor_oracle.py) computes results with the host-language XOR operator, independent of the ports' bit-decomposition loop.

Build and record a port with the shared binary-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm uint53_xor --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/u/uint53_xor/rust/build.json
python3 benchmarks/verify_binary_scalar.py --algorithms uint53_xor
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/u/uint53_xor.c`](../../../c/u/uint53_xor.c) |
| C3 | [`c3/u/uint53_xor.c3`](../../../c3/u/uint53_xor.c3) |
| C++ | [`cpp/u/uint53_xor.cpp`](../../../cpp/u/uint53_xor.cpp) |
| Elisa | [`elisa/u/uint53_xor.elisa`](../../../elisa/u/uint53_xor.elisa) |
| Nim | [`nim/u/uint53_xor.nim`](../../../nim/u/uint53_xor.nim) |
| Odin | [`odin/u/uint53_xor.odin`](../../../odin/u/uint53_xor.odin) |
| Rust | [`rust/u/uint53_xor.rs`](../../../rust/u/uint53_xor.rs) |
| V | [`v/u/uint53_xor.v`](../../../v/u/uint53_xor.v) |
| Zig | [`zig/u/uint53_xor.zig`](../../../zig/u/uint53_xor.zig) |

## TheAlgorithms reference

- [Lua `xor.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/xor.lua)
