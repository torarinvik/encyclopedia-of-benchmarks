# Single Bit Manipulation Operations

This benchmark packages the six pure operations from the pinned `single_bit_manipulation_operations.py` source behind one bounded scalar ABI.

## Contract

- Input is exactly `[opcode, number, position]`. `number` must fit signed 32-bit.
- Opcodes are 0 set bit, 1 clear bit, 2 flip bit, 3 test bit, 4 get bit, and 5 clear the least-significant set bit.
- Opcodes 0 through 4 require a bit position from 0 through 31. Opcode 5 requires `position=-1` as a packed sentinel.
- Return the exact Python integer result in signed `i64`; the boolean test returns 0 or 1. Negative values use Python's arithmetic right-shift semantics for the test operation. Invalid input returns `-1`.

The independent oracle is [`single_bit_manipulation_operations_oracle.py`](../../single_bit_manipulation_operations_oracle.py). The workload includes all operations, high-bit behavior, negative-number behavior, and invalid arguments.

## Pinned source

[TheAlgorithms/Python `bit_manipulation/single_bit_manipulation_operations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/single_bit_manipulation_operations.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Implementations

| Language | Source |
| --- | --- |
| C | [single_bit_manipulation_operations.c](../../../c/s/single_bit_manipulation_operations.c) |
| C3 | [single_bit_manipulation_operations.c3](../../../c3/s/single_bit_manipulation_operations.c3) |
| C++ | [single_bit_manipulation_operations.cpp](../../../cpp/s/single_bit_manipulation_operations.cpp) |
| Elisa | [single_bit_manipulation_operations.elisa](../../../elisa/s/single_bit_manipulation_operations.elisa) |
| Nim | [single_bit_manipulation_operations.nim](../../../nim/s/single_bit_manipulation_operations.nim) |
| Odin | [single_bit_manipulation_operations.odin](../../../odin/s/single_bit_manipulation_operations.odin) |
| Rust | [single_bit_manipulation_operations.rs](../../../rust/s/single_bit_manipulation_operations.rs) |
| V | [single_bit_manipulation_operations.v](../../../v/s/single_bit_manipulation_operations.v) |
| Zig | [single_bit_manipulation_operations.zig](../../../zig/s/single_bit_manipulation_operations.zig) |
