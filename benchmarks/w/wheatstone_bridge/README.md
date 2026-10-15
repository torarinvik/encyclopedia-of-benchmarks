# Wheatstone bridge

Calculate the unknown resistance in a balanced Wheatstone bridge.

## Contract

- The i64_array_float64 ABI accepts [resistance_1, resistance_2, resistance_3] and returns the unknown resistance in ohms.
- All three input resistances must be integers from 1 through 1,000,000.
- The implementation preserves the source expression order: (resistance_2 / resistance_1) * resistance_3.
- Invalid length or values return -1e300. Valid results use relative and absolute tolerance 1e-12.

## Source semantics

This follows the pinned [TheAlgorithms Python wheatstone_bridge.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/wheatstone_bridge.py). The source requires positive resistances and evaluates the balanced-bridge formula as (R2 / R1) * R3. The benchmark uses a bounded positive integer subset and maps source errors to the invalid sentinel.

## Workload

The workload includes the pinned examples, exact and fractional outputs, equal-arm cases, input bounds, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/wheatstone_bridge.c](../../../c/w/wheatstone_bridge.c) |
| C3 | [c3/w/wheatstone_bridge.c3](../../../c3/w/wheatstone_bridge.c3) |
| C++ | [cpp/w/wheatstone_bridge.cpp](../../../cpp/w/wheatstone_bridge.cpp) |
| Elisa | [elisa/w/wheatstone_bridge.elisa](../../../elisa/w/wheatstone_bridge.elisa) |
| Nim | [nim/w/wheatstone_bridge.nim](../../../nim/w/wheatstone_bridge.nim) |
| Odin | [odin/w/wheatstone_bridge.odin](../../../odin/w/wheatstone_bridge.odin) |
| Rust | [rust/w/wheatstone_bridge.rs](../../../rust/w/wheatstone_bridge.rs) |
| V | [v/w/wheatstone_bridge.v](../../../v/w/wheatstone_bridge.v) |
| Zig | [zig/w/wheatstone_bridge.zig](../../../zig/w/wheatstone_bridge.zig) |

The package uses the i64_array_float64 benchmark ABI.
