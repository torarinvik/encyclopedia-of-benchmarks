# Large-number addition

This benchmark isolates the pinned C++ `large_number` class's compound addition of one nonnegative decimal number into another.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[left_length, right_length, left_ascii_digits..., right_ascii_digits...]`. Each length is from 1 through 64, and each digit is the ASCII code for `0` through `9` (48 through 57). Each operand must be a canonical nonempty decimal string: leading zeroes are forbidden except for the one-character value `0`.

Construct a fresh `large_number` for each operand from its decimal string, apply `left += right`, and emit the resulting number as ASCII decimal bytes from most significant digit to least significant digit, with no NUL terminator. The pinned class stores digits least-significant first and propagates base-10 carry, appending digits when the sum grows. The output can contain at most 65 bytes. Malformed packing, unsupported lengths, non-digit input, or a noncanonical leading zero returns `-1`; a null output or capacity smaller than the required byte count returns `-2` without writes. Success returns the number of output bytes.

The two pinned headers preserve a leading zero in the class's representation and the string constructor silently ignores non-digit characters. This workload excludes those representation-specific cases by requiring canonical decimal operands. The separately overloaded `operator+` uses a static accumulator and is outside this workload; only fresh objects and `operator+=` are measured.

## Pinned sources

- C++ `large_number::operator+=`: https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/large_number.h
- C++-1 `large_number::operator+=` (matching additional repository): https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/large_number.h

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`large_number_oracle.py`](../../large_number_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/large_number.c`](../../../c/l/large_number.c) |
| C3 | [`c3/l/large_number.c3`](../../../c3/l/large_number.c3) |
| C++ | [`cpp/l/large_number.cpp`](../../../cpp/l/large_number.cpp) |
| Elisa | [`elisa/l/large_number.elisa`](../../../elisa/l/large_number.elisa) |
| Nim | [`nim/l/large_number.nim`](../../../nim/l/large_number.nim) |
| Odin | [`odin/l/large_number.odin`](../../../odin/l/large_number.odin) |
| Rust | [`rust/l/large_number.rs`](../../../rust/l/large_number.rs) |
| V | [`v/l/large_number.v`](../../../v/l/large_number.v) |
| Zig | [`zig/l/large_number.zig`](../../../zig/l/large_number.zig) |
