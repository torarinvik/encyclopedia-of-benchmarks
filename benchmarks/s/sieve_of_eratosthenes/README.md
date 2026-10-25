# Sieve of Eratosthenes

This benchmark uses the Sieve of Eratosthenes to count primes up to an inclusive limit.

## Contract

- The input is one signed 64-bit integer from 0 through 4096.
- The result is the number of primes in `[2, limit]`. Limits 0 and 1 return 0; negative or greater-than-4096 values return `-1`.
- Implementations mark multiples starting at `factor * factor` and use a fixed 4097-entry local buffer. They allocate no memory and use portable integer operations.

The pinned implementations generally return a list of primes or a boolean sieve. The Java and R sources also expose prime-count helpers. The `prime_sieve`, `prime_sieve_eratosthenes`, `eratosthenes_sieve`, `sieve_er`, `sieve2`, and `odd_sieve` filename candidates are cataloged as aliases; the PHP source leaves 1 in its output, which the shared contract corrects. This benchmark standardizes the result as the count, which allows every target language to use the same scalar ABI while preserving the sieve computation. The upper bound keeps the fixed local buffer and work bounded.

## Inspected upstream sources

- [C-Plus-Plus — `math/sieve_of_eratosthenes.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/sieve_of_eratosthenes.cpp)
- [C-Plus-Plus-1 — `math/sieve_of_eratosthenes.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/sieve_of_eratosthenes.cpp)
- [C-Sharp — `Algorithms/Other/SieveOfEratosthenes.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/SieveOfEratosthenes.cs)
- [Dart — `maths/sieve_of_eratosthenes.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/sieve_of_eratosthenes.dart)
- [Java — `src/main/java/com/thealgorithms/maths/SieveOfEratosthenes.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SieveOfEratosthenes.java)
- [JavaScript — `Dynamic-Programming/SieveOfEratosthenes.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/SieveOfEratosthenes.js)
- [JavaScript — `Maths/SieveOfEratosthenes.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/SieveOfEratosthenes.js)
- [Julia — `src/math/sieve_of_eratosthenes.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/sieve_of_eratosthenes.jl)
- [Lua — `src/math/prime/sieve_of_eratosthenes.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/prime/sieve_of_eratosthenes.lua)
- [Python — `maths/sieve_of_eratosthenes.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sieve_of_eratosthenes.py)
- [R — `mathematics/sieve_of_eratosthenes.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/sieve_of_eratosthenes.r)
- [Rust — `src/math/sieve_of_eratosthenes.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/sieve_of_eratosthenes.rs)
- [TypeScript — `maths/sieve_of_eratosthenes.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/sieve_of_eratosthenes.ts)
- [lac-dcc/Benchmarks — Shootout `sieve.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/sieve.c)
- [lac-dcc/Benchmarks — Benchmark Game `nsieve-bits.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/nsieve-bits/nsieve-bits.c)

The Shootout source repeats the byte-flag sieve over a fixed range and prints its count; `nsieve-bits` packs the flags into words and repeats the same sieve at three bounds. They are tracked as source aliases here because their core algorithm is still the Sieve of Eratosthenes. Their representation, output, and repetition profiles do not create additional algorithm packages.

## Workload and verification

`workload.json` covers small limits, prime and composite boundaries, a perfect-square limit, the maximum bound, and invalid signed inputs. The verifier exhausts every valid limit from 0 through 4096 against an independent trial-division oracle and checks every published workload case in all nine languages.

```sh
python3 benchmarks/verify_sieve_of_eratosthenes.py --elisa-compiler /absolute/path/to/elisac
```

