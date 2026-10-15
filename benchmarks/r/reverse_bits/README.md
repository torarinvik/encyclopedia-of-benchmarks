# Reverse Bits

Reverse the positions of all 32 bits in an unsigned 32-bit word. The returned integer represents that reversed bit pattern as a nonnegative unsigned value.

## Contract

- The scalar ABI accepts an integer from 0 through 4,294,967,295.
- Inputs outside that range return -1.
- Every call processes exactly 32 positions, including leading zero bits.
- The result is the unsigned numeric value of the reversed 32-bit pattern. This standardizes references whose native signed 32-bit return may be negative when the high result bit is set.
- The implementations use portable shifts and bit operations, with no architecture-specific instructions.

## Workload and verification

[workload.json](workload.json) includes the zero and maximum words, individual and highest bits, alternating patterns, the standard LeetCode example, and invalid signed 64-bit inputs. [verify_scalar.py](../../verify_scalar.py) checks an exhaustive 16-bit range, seeded 32-bit inputs, every bit position and its neighbors, and every workload record. All nine ports passed on the native host.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/reverse_bits.c](../../../c/r/reverse_bits.c) |
| C3 | [c3/r/reverse_bits.c3](../../../c3/r/reverse_bits.c3) |
| C++ | [cpp/r/reverse_bits.cpp](../../../cpp/r/reverse_bits.cpp) |
| Elisa | [elisa/r/reverse_bits.elisa](../../../elisa/r/reverse_bits.elisa) |
| Nim | [nim/r/reverse_bits.nim](../../../nim/r/reverse_bits.nim) |
| Odin | [odin/r/reverse_bits.odin](../../../odin/r/reverse_bits.odin) |
| Rust | [rust/r/reverse_bits.rs](../../../rust/r/reverse_bits.rs) |
| V | [v/r/reverse_bits.v](../../../v/r/reverse_bits.v) |
| Zig | [zig/r/reverse_bits.zig](../../../zig/r/reverse_bits.zig) |

## TheAlgorithms references

- [C LeetCode 190](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/190.c) reverses each bit position explicitly.
- [Java ReverseBits](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/ReverseBits.java), [Python reverse_bit](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/reverse_bits.py), and [Rust reverse_bits](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/reverse_bits.rs) process the same fixed-width word.
