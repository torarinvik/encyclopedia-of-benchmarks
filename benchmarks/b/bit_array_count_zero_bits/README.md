# Bit-array zero-bit count

Count unset bits in the pinned C# `BitArray.NumberOfZeroBits` method. The implementation scans a bounded bit vector and counts zero entries.

Pinned source: [TheAlgorithms/C-Sharp `BitArray.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/BitArray.cs).

## Contract

Input is a signed 64-bit array containing one bit per element, in the same order as the C# field. The array length is 0 through 4,096 and every element must be 0 or 1. The result is the number of zero bits. Empty input returns 0; malformed bits return -1. The contract uses a read-only array and scalar result.

## Workload and build

[`workload.json`](workload.json) includes empty, all-zero, all-one, mixed, invalid, and maximum-length inputs. Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bit_array_count_zero_bits --language LANGUAGE`; record with `python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/bit_array_count_zero_bits/LANGUAGE/build.json`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bit_array_count_zero_bits.c`](../../../c/b/bit_array_count_zero_bits.c) |
| C3 | [`c3/b/bit_array_count_zero_bits.c3`](../../../c3/b/bit_array_count_zero_bits.c3) |
| C++ | [`cpp/b/bit_array_count_zero_bits.cpp`](../../../cpp/b/bit_array_count_zero_bits.cpp) |
| Elisa | [`elisa/b/bit_array_count_zero_bits.elisa`](../../../elisa/b/bit_array_count_zero_bits.elisa) |
| Nim | [`nim/b/bit_array_count_zero_bits.nim`](../../../nim/b/bit_array_count_zero_bits.nim) |
| Odin | [`odin/b/bit_array_count_zero_bits.odin`](../../../odin/b/bit_array_count_zero_bits.odin) |
| Rust | [`rust/b/bit_array_count_zero_bits.rs`](../../../rust/b/bit_array_count_zero_bits.rs) |
| V | [`v/b/bit_array_count_zero_bits.v`](../../../v/b/bit_array_count_zero_bits.v) |
| Zig | [`zig/b/bit_array_count_zero_bits.zig`](../../../zig/b/bit_array_count_zero_bits.zig) |
