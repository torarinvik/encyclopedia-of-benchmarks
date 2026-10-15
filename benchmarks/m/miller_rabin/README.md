# Miller–Rabin primality test

This benchmark tests whether an integer is prime with the Miller–Rabin strong probable-prime test.

## Contract

- The input is a signed 64-bit integer. Negative values and values below 2 return `0` (composite); values above `2,147,483,647` return `-1` (outside the benchmark domain).
- The algorithm decomposes `n - 1` into an odd factor times a power of two and tests the fixed bases `[2, 3, 5, 7]`. It returns `1` when all bases pass and `0` when a witness proves the input composite.
- The pinned Rust source states that `[2, 3, 5, 7]` is deterministic below `3,215,031,751`, so it covers this benchmark's full signed 32-bit domain. Fixed bases make runs reproducible; the C++ source instead chooses random bases and the Rust source exposes configurable bases and returns a witness.
- Every modular product is bounded by `(2,147,483,647 - 1)^2`, which fits signed 64-bit arithmetic. The ports need no wider integer type or processor-specific instruction.

## Inspected upstream sources

- [C++ `math/miller_rabin.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/miller_rabin.cpp)
- [Rust `src/math/miller_rabin.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/miller_rabin.rs)
- [Additional C++ repository `math/miller_rabin.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/miller_rabin.cpp)

The C++ source uses random witnesses and the Rust source accepts the witness list as an argument. Their return conventions also differ. This benchmark fixes the bases and uses a shared boolean result so all nine ports perform the same deterministic test.

## Workload and verification

`workload.json` covers small values, Carmichael numbers, strong pseudoprimes to prefixes of the base list, the signed 32-bit boundary, and invalid values. The verifier checks every input from `0` through `100,000`, seeded values across the supported domain, signed boundaries, and every published workload case against independent trial division in all nine languages.

```sh
python3 benchmarks/verify_miller_rabin.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Source ports are in `m/` in all nine language directories.
