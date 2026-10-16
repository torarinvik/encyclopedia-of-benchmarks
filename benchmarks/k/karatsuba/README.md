# Karatsuba multiplication

Multiply two bounded nonnegative integers with a recursive three-product Karatsuba split.

## Contract

- ABI: `i64_array_scalar`, with exactly two inputs `[left, right]`.
- Each operand is an integer in `0..=1,000,000`. Negative values, out-of-range values, and malformed array lengths return `-1`.
- Return the exact product. The maximum result is `10^12`, which fits signed i64 and is exactly representable by the R source's binary64 arithmetic.
- The ports split operands by decimal digits and compute low, high, and summed-half products recursively. This implements the same three-product Karatsuba recurrence as the pinned binary-string C++ and BigInteger Java sources within the shared domain.

## Sources and workload

This package aligns related implementations whose source names differ:

- [TheAlgorithms/Python `karatsuba.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/karatsuba.py)
- [TheAlgorithms/R `karatsuba.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/karatsuba.r)
- [TheAlgorithms/C-Plus-Plus `karatsuba_algorithm_for_fast_multiplication.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/divide_and_conquer/karatsuba_algorithm_for_fast_multiplication.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `karatsuba_algorithm_for_fast_multiplication.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/divide_and_conquer/karatsuba_algorithm_for_fast_multiplication.cpp)
- [TheAlgorithms/Java `KaratsubaMultiplication.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/KaratsubaMultiplication.java)
- [TheAlgorithms/Rust `karatsuba_multiplication.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/karatsuba_multiplication.rs)

The common bound keeps every result exact in all source representations. The workload includes the Python example, digit-split boundaries, maximum operands, and malformed/out-of-range inputs. See [`workload.json`](workload.json).

Build and record Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm karatsuba --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/k/karatsuba/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms karatsuba --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/karatsuba.c`](../../../c/k/karatsuba.c) |
| C3 | [`c3/k/karatsuba.c3`](../../../c3/k/karatsuba.c3) |
| C++ | [`cpp/k/karatsuba.cpp`](../../../cpp/k/karatsuba.cpp) |
| Elisa | [`elisa/k/karatsuba.elisa`](../../../elisa/k/karatsuba.elisa) |
| Nim | [`nim/k/karatsuba.nim`](../../../nim/k/karatsuba.nim) |
| Odin | [`odin/k/karatsuba.odin`](../../../odin/k/karatsuba.odin) |
| Rust | [`rust/k/karatsuba.rs`](../../../rust/k/karatsuba.rs) |
| V | [`v/k/karatsuba.v`](../../../v/k/karatsuba.v) |
| Zig | [`zig/k/karatsuba.zig`](../../../zig/k/karatsuba.zig) |
