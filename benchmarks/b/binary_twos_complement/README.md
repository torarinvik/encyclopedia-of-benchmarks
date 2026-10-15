# Binary two's complement

Return the pinned Python routine's 0b-prefixed representation for a negative integer; zero returns 0b0.

## Contract

- The i64_scalar_bytes_output ABI accepts a signed 64-bit integer. Zero and all negative i64 values are supported; positive values return -1 with no output bytes.
- Valid output is the exact ASCII string returned by the source, including the 0b prefix. The result length is the number of output bytes.
- An insufficient output buffer returns -2. The longest valid result for a signed 64-bit input is 67 bytes.

## Source semantics

This follows the pinned [TheAlgorithms Python binary_twos_complement.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_twos_complement.py). The source accepts negative integers and zero, raises for positive values, and builds a sign-prefixed bit string. The ports reproduce its exact variable-width output, including the extra leading sign bit for negative powers of two.

## Workload

The workload covers zero, the source examples, negative powers of two, the signed 64-bit minimum, and positive inputs rejected by the source.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/binary_twos_complement.c](../../../c/b/binary_twos_complement.c) |
| C3 | [c3/b/binary_twos_complement.c3](../../../c3/b/binary_twos_complement.c3) |
| C++ | [cpp/b/binary_twos_complement.cpp](../../../cpp/b/binary_twos_complement.cpp) |
| Elisa | [elisa/b/binary_twos_complement.elisa](../../../elisa/b/binary_twos_complement.elisa) |
| Nim | [nim/b/binary_twos_complement.nim](../../../nim/b/binary_twos_complement.nim) |
| Odin | [odin/b/binary_twos_complement.odin](../../../odin/b/binary_twos_complement.odin) |
| Rust | [rust/b/binary_twos_complement.rs](../../../rust/b/binary_twos_complement.rs) |
| V | [v/b/binary_twos_complement.v](../../../v/b/binary_twos_complement.v) |
| Zig | [zig/b/binary_twos_complement.zig](../../../zig/b/binary_twos_complement.zig) |

Build with python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm binary_twos_complement --language c and record with benchmarks/run_i64_scalar_bytes_output.py.
