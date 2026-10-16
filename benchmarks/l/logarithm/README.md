# Base-2 Integer Logarithm

## Contract

For an integer `input` in `1..=4,294,967,295`, return `floor(log2(input))`, the index of its highest set bit. Inputs outside that range, including zero, return `-1`. The ABI accepts signed 64-bit input so the upper-bound check is explicit; valid values match the Go source’s `uint32` domain.

The ports use the pinned Go implementation’s five mask-and-shift steps, with O(1) time and O(1) space. Each mask tests a 16-, 8-, 4-, 2-, or 1-bit block and accumulates the matching shift.

## Workload

[`workload.json`](workload.json) covers powers of two, values between powers of two, the 16-bit boundary, the maximum valid `uint32`, and invalid bounds.

## TheAlgorithms references

- Go [`math/binary/logarithm.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/logarithm.go) provides `LogBase2(uint32)` using the same masks and shifts. Its zero input returns zero; the shared benchmark contract rejects zero with `-1`.
- Rust [`src/math/logarithm.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/logarithm.rs) implements an approximate general-base logarithm with a tolerance parameter. It does not match this floor-log2 operation and is excluded from this package’s source mapping.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/logarithm.c](../../../c/l/logarithm.c) |
| C3 | [c3/l/logarithm.c3](../../../c3/l/logarithm.c3) |
| C++ | [cpp/l/logarithm.cpp](../../../cpp/l/logarithm.cpp) |
| Elisa | [elisa/l/logarithm.elisa](../../../elisa/l/logarithm.elisa) |
| Nim | [nim/l/logarithm.nim](../../../nim/l/logarithm.nim) |
| Odin | [odin/l/logarithm.odin](../../../odin/l/logarithm.odin) |
| Rust | [rust/l/logarithm.rs](../../../rust/l/logarithm.rs) |
| V | [v/l/logarithm.v](../../../v/l/logarithm.v) |
| Zig | [zig/l/logarithm.zig](../../../zig/l/logarithm.zig) |
