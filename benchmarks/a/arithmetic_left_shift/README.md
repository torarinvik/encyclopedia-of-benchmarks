# Arithmetic left shift

This benchmark follows the Lua `uint53` arithmetic-left-shift module. The pinned module delegates to the logical-left-shift implementation, so high bits are discarded and the result wraps modulo `2^53`.

## Contract

- Input is two unsigned 64-bit ABI values `[n, shift]`.
- Valid `n` values are integers in `0..=2^53-1`; valid shift counts are `0..=53`.
- Return `(n * 2^shift) mod 2^53`, as a nonnegative signed 64-bit integer. The result is in `0..=2^53-1`.
- Invalid values return `-1`. This sentinel is outside the result domain.

The bound matches Lua's exact `uint53` integer range. Shift counts are bounded as documented by the source. The source module does not perform validation; invalid-input handling is supplied by this benchmark contract.

## Source and related operations

- [Lua `arithmetic_left_shift.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/arithmetic_left_shift.lua)
- [Lua `logical_left_shift.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/logical_left_shift.lua), which the arithmetic module returns directly

This is the canonical package for both pinned left-shift names: the arithmetic module returns the logical-left-shift function directly, so `logical_left_shift` has the same operation and can map here as an alias. The package is distinct from both right-shift operations.

## Workload and build

[`workload.json`](workload.json) covers identity, ordinary shifts, discarded high bits, maximum input and shift, zero, and invalid bounds. All nine ports use the shared `binary_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm arithmetic_left_shift --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/a/arithmetic_left_shift/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/a/arithmetic_left_shift.c`](../../../c/a/arithmetic_left_shift.c) |
| C3 | [`c3/a/arithmetic_left_shift.c3`](../../../c3/a/arithmetic_left_shift.c3) |
| C++ | [`cpp/a/arithmetic_left_shift.cpp`](../../../cpp/a/arithmetic_left_shift.cpp) |
| Elisa | [`elisa/a/arithmetic_left_shift.elisa`](../../../elisa/a/arithmetic_left_shift.elisa) |
| Nim | [`nim/a/arithmetic_left_shift.nim`](../../../nim/a/arithmetic_left_shift.nim) |
| Odin | [`odin/a/arithmetic_left_shift.odin`](../../../odin/a/arithmetic_left_shift.odin) |
| Rust | [`rust/a/arithmetic_left_shift.rs`](../../../rust/a/arithmetic_left_shift.rs) |
| V | [`v/a/arithmetic_left_shift.v`](../../../v/a/arithmetic_left_shift.v) |
| Zig | [`zig/a/arithmetic_left_shift.zig`](../../../zig/a/arithmetic_left_shift.zig) |
