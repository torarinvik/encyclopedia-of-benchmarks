# Sphenic number

Checks whether a nonnegative integer is sphenic by using its divisor count and its first divisors.

## Contract

- Uses the unary scalar ABI: `int64_t sphenic_number(int64_t value)`.
- Inputs in `[0, 1,000]` are accepted. Values outside the range return `-1`.
- Return `1` when the input has exactly eight positive divisors and its first three divisors are marked true by the source sieve; otherwise return `0`.
- On positive inputs, this is equivalent to `n = p*q*r` for three distinct primes. Eight divisors can also come from `p^7` or `p^3*q`; in either case the first three divisors include composite `p^2`, which the sieve marks false. For `p*q*r`, the first three divisors are `1`, `p`, and `q`; the source leaves sieve entry 1 true and marks both primes true. Zero has no positive divisors and returns `0`.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Dart `sphenic_number.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/sphenic_number.dart). Its global boolean table begins all true; `simple_seive()` marks composite indices through 1,000, and the program entry point calls the sieve before invoking the predicate. The predicate scans divisors from 1 through N, stores at most the first nine, then requires the stored count to equal eight and the sieve entries for the first three divisors to be true. This first-three-divisors check rules out the other eight-divisor exponent patterns (`p^7` and `p^3*q`) because they have composite `p^2` among their first three divisors. The shared domain is limited to 0..1,000 to fit the source table and avoid indexing beyond it. The ports reproduce the initialized table's classification, including its true entry for 1, using a bounded primality helper. Negative and larger values return `-1` under the benchmark contract.

## Workload and build

[`workload.json`](workload.json) covers zero, small non-sphenic values, primes, known sphenic values, and the sieve boundary. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm sphenic_number --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/s/sphenic_number/c/build.json
```

The nine implementations are in `c/s/sphenic_number.c`, `c3/s/sphenic_number.c3`, `cpp/s/sphenic_number.cpp`, `elisa/s/sphenic_number.elisa`, `nim/s/sphenic_number.nim`, `odin/s/sphenic_number.odin`, `rust/s/sphenic_number.rs`, `v/s/sphenic_number.v`, and `zig/s/sphenic_number.zig`.

Verify the nine ports against the independent square-free factorization oracle with `python3 benchmarks/verify_scalar.py --algorithms sphenic_number`.
