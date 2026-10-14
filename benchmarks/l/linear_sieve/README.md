# Linear sieve

This benchmark uses the linear (Euler) sieve to count primes through an inclusive upper limit. It also maintains the smallest prime factor needed by the sieve recurrence.

## Contract

- The input is one signed 64-bit integer from 0 through 4096.
- The result is the number of primes in `[2, limit]`. Limits 0 and 1 return 0; negative or greater-than-4096 values return `-1`.
- The implementation records each composite once, using its smallest prime factor, and stops the inner prime loop when the prime exceeds that factor or the product exceeds the limit.
- A fixed 4662-element signed 64-bit state array stores the smallest-prime-factor table, generated primes, and count. It allocates no memory.

The pinned JavaScript and Scala sources return prime lists. Rust also builds the smallest-prime-factor table for later factorization. The local contract standardizes the result as a prime count to use one scalar ABI across all nine target languages. The Rust source's inner-loop bound differs from the standard `p <= smallest_prime_factor[i]` condition; the local ports use the standard linear-sieve condition, which marks each composite once.

## Inspected upstream sources

- [JavaScript — `Maths/LinearSieve.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/LinearSieve.js)
- [Rust — `src/math/linear_sieve.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/linear_sieve.rs)
- [Scala — `src/main/scala/Mathematics/LinearSieve.scala`](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/LinearSieve.scala)

## Workload and verification

`workload.json` shares prime-count boundaries with the Eratosthenes benchmark. The verifier checks every limit from 0 through 4096 against an independent trial-division oracle, plus invalid signed inputs and every published workload case.

```sh
python3 benchmarks/verify_linear_sieve.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Source ports are in `l/` in all nine language directories.
