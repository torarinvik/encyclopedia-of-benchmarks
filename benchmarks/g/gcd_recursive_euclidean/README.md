# Recursive subtraction Euclidean GCD

## Contract

For positive integer operands from 1 through 128, return their greatest common divisor. Inputs containing zero or an operand above 128 return `-1`.

The exported C ABI entry point is:

```c
int64_t gcd_recursive_euclidean(uint64_t left, uint64_t right);
```

The pinned C++ implementation checks that both values are positive, returns the operand when they are equal, and otherwise recursively subtracts the smaller operand from the larger. Despite the source filename and comment, its recursive step uses subtraction rather than the remainder operator. The 1..128 bound keeps every result representable and limits recursion to at most 128 calls.

The source throws for nonpositive input before reaching its later checks for zero. The shared ABI uses `-1` for zero and out-of-bound operands instead of throwing. The contract includes only the positive domain where the source's recursive algorithm is defined.

This is distinct from [`gcd`](../gcd/README.md), which uses the remainder step `(left, right) = (right, left % right)` and supports zero operands.

## Workload and recording

[`workload.json`](workload.json) covers equal inputs, the maximum input, a deep subtraction path, shared factors, coprime operands, reversed operand order, and invalid inputs. Build and record with the `binary_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm gcd_recursive_euclidean --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/g/gcd_recursive_euclidean/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gcd_recursive_euclidean.c`](../../../c/g/gcd_recursive_euclidean.c) |
| C3 | [`c3/g/gcd_recursive_euclidean.c3`](../../../c3/g/gcd_recursive_euclidean.c3) |
| C++ | [`cpp/g/gcd_recursive_euclidean.cpp`](../../../cpp/g/gcd_recursive_euclidean.cpp) |
| Elisa | [`elisa/g/gcd_recursive_euclidean.elisa`](../../../elisa/g/gcd_recursive_euclidean.elisa) |
| Nim | [`nim/g/gcd_recursive_euclidean.nim`](../../../nim/g/gcd_recursive_euclidean.nim) |
| Odin | [`odin/g/gcd_recursive_euclidean.odin`](../../../odin/g/gcd_recursive_euclidean.odin) |
| Rust | [`rust/g/gcd_recursive_euclidean.rs`](../../../rust/g/gcd_recursive_euclidean.rs) |
| V | [`v/g/gcd_recursive_euclidean.v`](../../../v/g/gcd_recursive_euclidean.v) |
| Zig | [`zig/g/gcd_recursive_euclidean.zig`](../../../zig/g/gcd_recursive_euclidean.zig) |

## TheAlgorithms sources

- [C++ `gcd_recursive_euclidean.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/gcd_recursive_euclidean.cpp)
- [Additional C++ `gcd_recursive_euclidean.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/gcd_recursive_euclidean.cpp)
