# Sieve of Atkin

This benchmark uses the Sieve of Atkin to count primes through an inclusive upper limit.

## Contract

- The input is one signed 64-bit integer from 0 through 4096.
- The result is the number of primes in `[2, limit]`. Limits 0 and 1 return 0; negative or greater-than-4096 values return `-1`.
- The implementation toggles candidates with the three quadratic forms modulo 12, then removes multiples of each candidate's square. It uses a fixed 4097-entry local buffer and allocates no memory.
- Prime counts include 2 and 3 explicitly; the quadratic sieve candidates begin at 5.

The inspected upstream implementations return prime lists. The local contract standardizes their result as a prime count so all nine target languages can use the same scalar ABI. The fixed upper bound keeps stack storage and runtime bounded.

## Inspected upstream sources

- [Java — `src/main/java/com/thealgorithms/maths/SieveOfAtkin.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SieveOfAtkin.java)
- [Python — `maths/sieve_of_atkin.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sieve_of_atkin.py)

## Workload and verification

`workload.json` covers the first prime boundaries, a perfect-square limit, familiar prime-count limits, the maximum bound, and invalid signed inputs. The verifier checks every valid limit from 0 through 4096 against an independent trial-division oracle and checks every published workload case in all nine languages.

```sh
python3 benchmarks/verify_sieve_of_atkin.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Source ports are in `s/` in all nine language directories.
