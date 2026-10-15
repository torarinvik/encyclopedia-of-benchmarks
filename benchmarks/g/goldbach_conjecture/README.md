# Goldbach Conjecture

Find the first prime pair that sums to a positive even input, following the scan order in the pinned Java implementation.

## Contract

- The input is an even signed 64-bit integer from 4 through 4,096. The Java source accepts an `int`; the smaller benchmark bound keeps its linear candidate scan practical and every supported value has a prime decomposition.
- The implementation tests candidates `i` in ascending order from zero through `n / 2`, returning the first pair `(i, n - i)` for which both values are prime. The pair is therefore ascending and the first component is the smallest possible prime in the source's scan order.
- The scalar byte-output ABI writes the two positive values as little-endian signed 32-bit integers, first component followed by second component. A successful call returns 8.
- Inputs outside the stated even range return `-1`, mapping the Java exception path. A caller-provided output buffer with fewer than 8 bytes returns `-2` without writing.

This package benchmarks the source's ordered search for a decomposition, not just whether a decomposition exists. The imported Java primality check rejects values below 2 and tests odd divisors through the integer square root; the benchmark ports preserve that result while bounding the domain.

## Workload

[`workload.json`](workload.json) records small equal and unequal decompositions, a larger input, the upper bound, invalid inputs, and an insufficient-capacity call. It uses the `i64_scalar_bytes_output` ABI family and the `goldbach_pair_i32le` expected-output encoding.

## Pinned source

- [Java `GoldbachConjecture.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/GoldbachConjecture.java)
- [Java `PrimeCheck.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/PrimeCheck.java)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/g/goldbach_conjecture.c](../../../c/g/goldbach_conjecture.c) |
| C3 | [c3/g/goldbach_conjecture.c3](../../../c3/g/goldbach_conjecture.c3) |
| C++ | [cpp/g/goldbach_conjecture.cpp](../../../cpp/g/goldbach_conjecture.cpp) |
| Elisa | [elisa/g/goldbach_conjecture.elisa](../../../elisa/g/goldbach_conjecture.elisa) |
| Nim | [nim/g/goldbach_conjecture.nim](../../../nim/g/goldbach_conjecture.nim) |
| Odin | [odin/g/goldbach_conjecture.odin](../../../odin/g/goldbach_conjecture.odin) |
| Rust | [rust/g/goldbach_conjecture.rs](../../../rust/g/goldbach_conjecture.rs) |
| V | [v/g/goldbach_conjecture.v](../../../v/g/goldbach_conjecture.v) |
| Zig | [zig/g/goldbach_conjecture.zig](../../../zig/g/goldbach_conjecture.zig) |

Build with `python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm goldbach_conjecture --language c` and record with `benchmarks/run_i64_scalar_bytes_output.py`.
