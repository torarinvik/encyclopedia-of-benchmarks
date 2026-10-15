# Unsigned 53-bit Bitwise XOR

Computes the bitwise exclusive OR of two values in the unsigned safe-integer domain.

## Contract

- Input is two unsigned 64-bit ABI values `[n, m]`. Each must be in `0..=9,007,199,254,740,991` (`2^53 - 1`); otherwise return `-1`.
- Return `n XOR m`, in the same range. The `-1` sentinel is outside the valid result domain.
- The pinned Lua source extracts both least-significant bits while both operands remain nonzero, adds their sum modulo two at the current bit position, then shifts the remaining operand into place. The ports preserve that exact operation using integer arithmetic and avoid multiplying the two inputs for the loop condition, which could overflow a fixed-width integer.
- The maximum width is 53 bits, so time and auxiliary space are O(1) for this bounded contract.

## Source and similarly named algorithms

- [TheAlgorithms/Lua `src/bit/uint53/xor.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/xor.lua)
- The Go and Rust candidates named `xor` are bytewise XOR ciphers and belong with the separate `xor_cipher` benchmark. They do not implement this integer operation.

## Workload and build

`workload.json` covers zero operands, equal and different operands, byte boundaries, top-domain bits, maximum values, and invalid unsigned boundaries. Build with `python3 benchmarks/build_abi.py --family binary_scalar --algorithm uint53_bitwise_xor --language LANGUAGE`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/uint53_bitwise_xor.c`](../../../c/u/uint53_bitwise_xor.c) |
| C3 | [`c3/u/uint53_bitwise_xor.c3`](../../../c3/u/uint53_bitwise_xor.c3) |
| C++ | [`cpp/u/uint53_bitwise_xor.cpp`](../../../cpp/u/uint53_bitwise_xor.cpp) |
| Elisa | [`elisa/u/uint53_bitwise_xor.elisa`](../../../elisa/u/uint53_bitwise_xor.elisa) |
| Nim | [`nim/u/uint53_bitwise_xor.nim`](../../../nim/u/uint53_bitwise_xor.nim) |
| Odin | [`odin/u/uint53_bitwise_xor.odin`](../../../odin/u/uint53_bitwise_xor.odin) |
| Rust | [`rust/u/uint53_bitwise_xor.rs`](../../../rust/u/uint53_bitwise_xor.rs) |
| V | [`v/u/uint53_bitwise_xor.v`](../../../v/u/uint53_bitwise_xor.v) |
| Zig | [`zig/u/uint53_bitwise_xor.zig`](../../../zig/u/uint53_bitwise_xor.zig) |
