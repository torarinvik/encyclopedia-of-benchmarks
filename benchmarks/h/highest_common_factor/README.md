# Highest common factor

Compute the greatest common factor with the recursive subtractive method from the pinned MATLAB implementation.

## Contract

- ABI: `binary_scalar`, with two unsigned 64-bit inputs and a signed 64-bit result.
- Inputs are integers from 0 through 64. This bounds recursion depth while retaining zero, equal, shared-factor, and coprime cases.
- Return the greatest common factor. If one input is zero, return the other; if both are zero, return zero.
- The recursive method repeatedly subtracts the smaller positive value from the larger until they are equal. Its time and stack use are `O((x + y) / gcd(x, y))` in the bounded domain.

## Source

This follows the pinned [TheAlgorithms MATLAB `highest_common_factor.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/highest_common_factor.m). The source handles either zero, then equality, and recursively subtracts the smaller operand from the larger. The bounded benchmark domain uses nonnegative integers, where those cases terminate with the mathematical GCD.

## Workload

[`workload.json`](workload.json) covers zero inputs, equal values, shared factors, coprime pairs, and inputs that require repeated subtraction.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/highest_common_factor.c`](../../../c/h/highest_common_factor.c) |
| C3 | [`c3/g/highest_common_factor.c3`](../../../c3/h/highest_common_factor.c3) |
| C++ | [`cpp/g/highest_common_factor.cpp`](../../../cpp/h/highest_common_factor.cpp) |
| Elisa | [`elisa/g/highest_common_factor.elisa`](../../../elisa/h/highest_common_factor.elisa) |
| Nim | [`nim/g/highest_common_factor.nim`](../../../nim/h/highest_common_factor.nim) |
| Odin | [`odin/g/highest_common_factor.odin`](../../../odin/h/highest_common_factor.odin) |
| Rust | [`rust/g/highest_common_factor.rs`](../../../rust/h/highest_common_factor.rs) |
| V | [`v/g/highest_common_factor.v`](../../../v/h/highest_common_factor.v) |
| Zig | [`zig/g/highest_common_factor.zig`](../../../zig/h/highest_common_factor.zig) |

All ports use portable integer operations and the shared `binary_scalar` ABI.
