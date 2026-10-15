# Logical right shift

This benchmark follows the Lua `uint53` logical-right-shift function. It shifts the input toward bit zero and fills all vacated high bits with zero.

## Contract

- Input is two unsigned 64-bit ABI values `[n, shift]`.
- Valid `n` values are integers in `0..=2^53-1`; valid shift counts are `0..=53`.
- Return `floor(n / 2^shift)` as a nonnegative signed 64-bit integer. The result is in `0..=2^53-1`.
- Invalid values return `-1`, outside the valid result domain.

The source documents the `uint53` and `0..53` domains but does not validate them. This benchmark applies those bounds and supplies a deterministic invalid-input result.

## Source and related operations

- [Lua `logical_right_shift.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/logical_right_shift.lua)

This operation fills with zeroes; [`arithmetic_right_shift`](../../a/arithmetic_right_shift/README.md) instead fills vacated bits from original bit 52.

## Workload and build

[`workload.json`](workload.json) covers identity, zero, ordinary shifts, the largest input, shift counts 52 and 53, and invalid bounds. All nine ports use the shared `binary_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm logical_right_shift --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/l/logical_right_shift/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/l/logical_right_shift.c`](../../../c/l/logical_right_shift.c) |
| C3 | [`c3/l/logical_right_shift.c3`](../../../c3/l/logical_right_shift.c3) |
| C++ | [`cpp/l/logical_right_shift.cpp`](../../../cpp/l/logical_right_shift.cpp) |
| Elisa | [`elisa/l/logical_right_shift.elisa`](../../../elisa/l/logical_right_shift.elisa) |
| Nim | [`nim/l/logical_right_shift.nim`](../../../nim/l/logical_right_shift.nim) |
| Odin | [`odin/l/logical_right_shift.odin`](../../../odin/l/logical_right_shift.odin) |
| Rust | [`rust/l/logical_right_shift.rs`](../../../rust/l/logical_right_shift.rs) |
| V | [`v/l/logical_right_shift.v`](../../../v/l/logical_right_shift.v) |
| Zig | [`zig/l/logical_right_shift.zig`](../../../zig/l/logical_right_shift.zig) |
