# NIMPLY gate

Evaluate the pinned Python NIMPLY truth table, which is true only when the first input is 1 and the second is 0.

## Contract

The `i64_array_scalar` ABI accepts exactly two signed integers `[input_1, input_2]`; each must be 0 or 1. It returns 1 for `[1, 0]`, 0 for the other three Boolean pairs, and -1 for malformed input.

[`workload.json`](workload.json) covers all four source truth-table rows and malformed lengths and values. The nine portable implementations are [`c/n/nimply_gate.c`](../../../c/n/nimply_gate.c), [`c3/n/nimply_gate.c3`](../../../c3/n/nimply_gate.c3), [`cpp/n/nimply_gate.cpp`](../../../cpp/n/nimply_gate.cpp), [`elisa/n/nimply_gate.elisa`](../../../elisa/n/nimply_gate.elisa), [`nim/n/nimply_gate.nim`](../../../nim/n/nimply_gate.nim), [`odin/n/nimply_gate.odin`](../../../odin/n/nimply_gate.odin), [`rust/n/nimply_gate.rs`](../../../rust/n/nimply_gate.rs), [`v/n/nimply_gate.v`](../../../v/n/nimply_gate.v), and [`zig/n/nimply_gate.zig`](../../../zig/n/nimply_gate.zig). The pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/boolean_algebra/nimply_gate.py) defines the truth table.
