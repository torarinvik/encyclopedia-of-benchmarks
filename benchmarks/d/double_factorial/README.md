# Double factorial

## Contract

Compute `n!!`, the product of positive integers no greater than `n` with the same parity as `n`; `0!!` and `1!!` are both `1`. Inputs from `0` through `33` return the exact signed 64-bit result. Negative inputs and values above `33`, whose double factorial exceeds `INT64_MAX`, return `-1`.

The exported C ABI entry point is `int64_t double_factorial(int64_t n);`. The nine implementations multiply downward by two. This preserves the iterative algorithm in the pinned C++ and Python sources while making the result range explicit for a fixed-width ABI.

## Workload and verification

[`workload.json`](workload.json) covers both parity classes, the largest accepted odd and even inputs, overflow, and signed boundaries. [`verify_scalar.py`](../../verify_scalar.py) checks all inputs from -4 through 40 against Python arbitrary-precision multiplication, plus signed-width endpoints.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/double_factorial.c`](../../../c/d/double_factorial.c) |
| C3 | [`c3/d/double_factorial.c3`](../../../c3/d/double_factorial.c3) |
| C++ | [`cpp/d/double_factorial.cpp`](../../../cpp/d/double_factorial.cpp) |
| Elisa | [`elisa/d/double_factorial.elisa`](../../../elisa/d/double_factorial.elisa) |
| Nim | [`nim/d/double_factorial.nim`](../../../nim/d/double_factorial.nim) |
| Odin | [`odin/d/double_factorial.odin`](../../../odin/d/double_factorial.odin) |
| Rust | [`rust/d/double_factorial.rs`](../../../rust/d/double_factorial.rs) |
| V | [`v/d/double_factorial.v`](../../../v/d/double_factorial.v) |
| Zig | [`zig/d/double_factorial.zig`](../../../zig/d/double_factorial.zig) |

## TheAlgorithms references

- [C++ `double_factorial.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/double_factorial.cpp) and [the additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/double_factorial.cpp)
- [C-Sharp `DoubleFactorial.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/DoubleFactorial.cs)
- [Python `double_factorial.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/double_factorial.py)
