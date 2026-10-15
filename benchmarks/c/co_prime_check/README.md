# Co-prime check

Checks whether two integers are relatively prime by computing their greatest common divisor with the Euclidean algorithm.

## Contract

- Uses the binary scalar ABI: `int64_t co_prime_check(uint64_t first, uint64_t second)`.
- Each input is a nonnegative signed 32-bit value in `[0, 2,147,483,647]`.
- Return `1` when `gcd(first, second) == 1`; otherwise return `0`.
- Inputs outside the range return `-1`.
- Zero follows the standard GCD identity: `(0, 1)` and `(1, 0)` are co-prime, while `(0, 0)` is not.

## Source semantics

The benchmark follows the pinned [TheAlgorithms JavaScript `CoPrimeCheck.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/CoPrimeCheck.js) and its imported [Euclidean GCD helper](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/GetEuclidGCD.js). The source returns whether the helper's GCD result equals one. The helper applies absolute values before Euclidean reduction, so the source supports negative integers too; the shared contract narrows inputs to nonnegative int32 values, which are exactly represented by JavaScript numbers and fit the unsigned binary scalar ABI. The implementations use the same Euclidean reduction and explicitly preserve the zero cases.

## Workload and build

[`workload.json`](workload.json) covers zero pairs, unit inputs, equal inputs, co-prime pairs, shared factors, and values near the int32 boundary. Build and record with the binary scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm co_prime_check --language c
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/c/co_prime_check/c/build.json
```

The nine implementations are in `c/c/co_prime_check.c`, `c3/c/co_prime_check.c3`, `cpp/c/co_prime_check.cpp`, `elisa/c/co_prime_check.elisa`, `nim/c/co_prime_check.nim`, `odin/c/co_prime_check.odin`, `rust/c/co_prime_check.rs`, `v/c/co_prime_check.v`, and `zig/c/co_prime_check.zig`.
