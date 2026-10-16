# Complex Arithmetic

This benchmark covers exact complex-number field operations shared by the pinned Lua `complex` module and the two identical C++ `complex_numbers` files: addition, subtraction, multiplication, exact division, conjugation, and equality. The implementations use ordinary scalar arithmetic and serialize a pair of signed 64-bit integers in little-endian order.

## Contract

- Input is `[operation, real_a, imaginary_a, real_b, imaginary_b]` with exactly five signed 64-bit values. Operation codes are `0` add, `1` subtract, `2` multiply, `3` divide, `4` conjugate `a`, and `5` compare for equality.
- Each component is an integer from `-100000` through `100000`. These values form an exact integer subset of the upstream double-valued complex types.
- Division is accepted only when `b` is nonzero and both quotient components are exact integers. Fractional divisions and division by zero return `-1`.
- Success returns `2` and writes `[real, imaginary]` as two little-endian signed 64-bit values. Equality writes `1` or `0` in the first slot and `0` in the second. The maximum output is 16 bytes.
- Invalid input returns `-1`. A null or undersized output buffer returns `-2`.

The Lua module also provides square root, integer powers, polar conversion, magnitude, and string formatting; the C++ class provides polar construction, magnitude, argument, and stream formatting. Those operations are outside this exact-integer contract. Console tests and random input generation are not part of the benchmark.

## Inspected upstream sources

- [TheAlgorithms/Lua `complex.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/complex.lua) defines addition, subtraction, multiplication, division, conjugation, and equality through scalar real and imaginary components. Its license is [MIT](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/LICENSE).
- [TheAlgorithms/C-Plus-Plus `complex_numbers.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/complex_numbers.cpp) and [TheAlgorithms/C-Plus-Plus-1 copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/complex_numbers.cpp) are identical. They expose the same six operations in their shared exact-integer domain. Both repositories use [MIT](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/LICENSE) and [MIT](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/LICENSE) licenses.

[`workload.json`](workload.json) exercises all six operations, negative values, exact and inexact division, zero divisors, component bounds, malformed inputs, and insufficient capacity. [`benchmarks/complex_arithmetic_oracle.py`](../../complex_arithmetic_oracle.py) independently checks the integer formulas.

Build and verify with the shared byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm complex_arithmetic --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm complex_arithmetic
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/c/complex_arithmetic.c`](../../../c/c/complex_arithmetic.c) |
| C3 | [`c3/c/complex_arithmetic.c3`](../../../c3/c/complex_arithmetic.c3) |
| C++ | [`cpp/c/complex_arithmetic.cpp`](../../../cpp/c/complex_arithmetic.cpp) |
| Elisa | [`elisa/c/complex_arithmetic.elisa`](../../../elisa/c/complex_arithmetic.elisa) |
| Nim | [`nim/c/complex_arithmetic.nim`](../../../nim/c/complex_arithmetic.nim) |
| Odin | [`odin/c/complex_arithmetic.odin`](../../../odin/c/complex_arithmetic.odin) |
| Rust | [`rust/c/complex_arithmetic.rs`](../../../rust/c/complex_arithmetic.rs) |
| V | [`v/c/complex_arithmetic.v`](../../../v/c/complex_arithmetic.v) |
| Zig | [`zig/c/complex_arithmetic.zig`](../../../zig/c/complex_arithmetic.zig) |
