# Arithmetic right shift

This benchmark follows the Lua `uint53` arithmetic (“sticky”) right shift. In this 53-bit unsigned representation, bit 52 acts as the sign bit: vacated high bits are filled with its value.

## Contract

- Input is two unsigned 64-bit ABI values `[n, shift]`.
- Valid `n` values are integers in `0..=2^53-1`; valid shift counts are `0..=53`.
- Let `msb = floor(n / 2^52)` and `fill = 2^53 - 2^(53-shift)`. Return `msb * fill + floor(n / 2^shift)` as a nonnegative signed 64-bit integer.
- Valid results are in `0..=2^53-1`. Invalid values return `-1`, outside that result domain.

Shift zero returns `n`. A shift of 53 returns `2^53-1` when bit 52 is set and zero otherwise. The source module documents the `uint53` and `0..53` domains without validating them; invalid-input handling is supplied by this benchmark contract.

## Source and related operations

- [Lua `arithmetic_right_shift.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/arithmetic_right_shift.lua)

This operation preserves the top bit during right shifts. The separate [`logical_right_shift`](../../l/logical_right_shift/README.md) benchmark fills vacated bits with zeroes.

## Workload and build

[`workload.json`](workload.json) covers identity, zero, ordinary shifts, both top-bit states, shift counts 52 and 53, and invalid bounds. All nine ports use the shared `binary_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm arithmetic_right_shift --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/a/arithmetic_right_shift/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/a/arithmetic_right_shift.c`](../../../c/a/arithmetic_right_shift.c) |
| C3 | [`c3/a/arithmetic_right_shift.c3`](../../../c3/a/arithmetic_right_shift.c3) |
| C++ | [`cpp/a/arithmetic_right_shift.cpp`](../../../cpp/a/arithmetic_right_shift.cpp) |
| Elisa | [`elisa/a/arithmetic_right_shift.elisa`](../../../elisa/a/arithmetic_right_shift.elisa) |
| Nim | [`nim/a/arithmetic_right_shift.nim`](../../../nim/a/arithmetic_right_shift.nim) |
| Odin | [`odin/a/arithmetic_right_shift.odin`](../../../odin/a/arithmetic_right_shift.odin) |
| Rust | [`rust/a/arithmetic_right_shift.rs`](../../../rust/a/arithmetic_right_shift.rs) |
| V | [`v/a/arithmetic_right_shift.v`](../../../v/a/arithmetic_right_shift.v) |
| Zig | [`zig/a/arithmetic_right_shift.zig`](../../../zig/a/arithmetic_right_shift.zig) |
