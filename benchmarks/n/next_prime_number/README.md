# Next prime number

This benchmark finds the smallest prime strictly greater than a signed integer.

## Contract

- The input is one signed 64-bit integer from -4096 through 4096.
- The result is the smallest prime strictly greater than the input. Inputs below 2 return 2; values outside the documented input range return `-1`.
- Each candidate is checked by trial division through its square root. The implementation uses integer division for the bound and does not depend on architecture-specific instructions.
- The fixed input range bounds the candidate search; the largest valid input returns 4099.

The pinned Python source documents the strict-greater-than behavior, including results of 2 for negative values and zero. The shared contract bounds its arbitrary-precision input domain so that all nine target languages use the same signed 64-bit scalar ABI.

## Inspected upstream source

- [Python — `maths/next_prime_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/next_prime_number.py)

## Workload and verification

`workload.json` covers negative inputs, 0 and 1, primes, composites, a square, the upper boundary, and invalid signed inputs. The verifier checks every supported input from -4096 through 4096 against an independent trial-division search and checks every published workload case in all nine languages.

```sh
python3 benchmarks/verify_next_prime_number.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Source ports are in `n/` in all nine language directories.
