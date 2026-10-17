# Multiply array

Multiply the values in an array from left to right. The empty array has the multiplicative identity `1`; any zero factor makes the result `0`.

## Contract

- The `i64_array_scalar` input is the array of factors itself, with no count prefix.
- A valid array has 0 through 9 values, each in the inclusive range 0 through 99. The result is the exact signed 64-bit product.
- A null input pointer with length zero is a valid empty array and returns `1`. A null pointer with positive length, a length above 9, or a value outside 0 through 99 returns `-1`.
- The largest valid product is `99^9 = 913517247483640899`, which fits in a signed 64-bit integer. Ten factors are outside the contract; ten factors of 99 would overflow signed 64-bit arithmetic.
- The input array is read-only. Implementations initialize the accumulator to `1` and multiply each factor in order.

## Workload and source

[`workload.json`](workload.json) covers the empty and null-empty inputs, identity and zero factors, mixed factors, the maximum valid product, invalid lengths, invalid factor bounds, and null input with a positive length. [`benchmarks/mul_array_oracle.py`](../../mul_array_oracle.py) is an independent exact-integer oracle.

The algorithm is based on Solidity [`MulArray.mulArr`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/MulArray.sol). The source initializes its result to 1 and multiplies every array element; Solidity 0.8 reverts on arithmetic overflow. The benchmark's nine-element bound ensures every valid result fits in the shared signed 64-bit scalar ABI.

| Language | Source |
| --- | --- |
| C | [c/m/mul_array.c](../../../c/m/mul_array.c) |
| C3 | [c3/m/mul_array.c3](../../../c3/m/mul_array.c3) |
| C++ | [cpp/m/mul_array.cpp](../../../cpp/m/mul_array.cpp) |
| Elisa | [elisa/m/mul_array.elisa](../../../elisa/m/mul_array.elisa) |
| Nim | [nim/m/mul_array.nim](../../../nim/m/mul_array.nim) |
| Odin | [odin/m/mul_array.odin](../../../odin/m/mul_array.odin) |
| Rust | [rust/m/mul_array.rs](../../../rust/m/mul_array.rs) |
| V | [v/m/mul_array.v](../../../v/m/mul_array.v) |
| Zig | [zig/m/mul_array.zig](../../../zig/m/mul_array.zig) |

Build with the shared `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
