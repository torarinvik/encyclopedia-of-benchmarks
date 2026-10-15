# Faster perfect numbers

Generate every even perfect number less than or equal to an input limit by enumerating prime exponents, applying the Lucas–Lehmer test to the corresponding Mersenne numbers, and using the Euclid–Euler formula.

## Contract

- The input limit is a signed 64-bit integer in `0..=2,305,843,009,213,693,951`. This upper bound keeps the pinned Rust helper's `num * 8 + 1` calculation within a 64-bit `usize`.
- The output is the ascending list of perfect numbers not greater than the limit. Each value is encoded as a signed 64-bit integer in little-endian byte order. The result is the number of bytes written; an empty list returns `0`.
- Negative inputs and inputs above the supported limit return `-1`. If the output buffer cannot hold the full list, the function returns `-2` without writing.
- At most eight values are returned. The largest is `2,305,843,008,139,952,128`, which fits signed 64-bit output.

The ports preserve the source's prime-exponent search and Lucas–Lehmer recurrence. They calculate the search bound with integer division by four, which yields the same eligible prime exponents throughout the supported range while avoiding floating-point boundary variation.

## Relation to `perfect_number`

The existing [`perfect_number`](../../p/perfect_number/README.md) benchmark asks whether one input is perfect. This benchmark generates the ordered list of all perfect numbers up to a limit using Mersenne-prime exponents, so it has a different input/output contract and algorithm.

## Workload and ABI

[`workload.json`](workload.json) records empty results, each newly reached perfect number, values immediately around sequence boundaries, the largest supported input, and invalid inputs. The output uses the shared `i64_scalar_bytes_output` ABI with a 256-byte output buffer.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/faster_perfect_numbers.c`](../../../c/f/faster_perfect_numbers.c) |
| C3 | [`c3/f/faster_perfect_numbers.c3`](../../../c3/f/faster_perfect_numbers.c3) |
| C++ | [`cpp/f/faster_perfect_numbers.cpp`](../../../cpp/f/faster_perfect_numbers.cpp) |
| Elisa | [`elisa/f/faster_perfect_numbers.elisa`](../../../elisa/f/faster_perfect_numbers.elisa) |
| Nim | [`nim/f/faster_perfect_numbers.nim`](../../../nim/f/faster_perfect_numbers.nim) |
| Odin | [`odin/f/faster_perfect_numbers.odin`](../../../odin/f/faster_perfect_numbers.odin) |
| Rust | [`rust/f/faster_perfect_numbers.rs`](../../../rust/f/faster_perfect_numbers.rs) |
| V | [`v/f/faster_perfect_numbers.v`](../../../v/f/faster_perfect_numbers.v) |
| Zig | [`zig/f/faster_perfect_numbers.zig`](../../../zig/f/faster_perfect_numbers.zig) |

## TheAlgorithms sources

- [Rust `faster_perfect_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/faster_perfect_numbers.rs)
- [Rust `mersenne_primes.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/mersenne_primes.rs)
- [Rust `prime_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/prime_numbers.rs)
