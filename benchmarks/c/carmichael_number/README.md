# Carmichael number

Checks whether an integer is a Carmichael number using the universal Fermat congruence for coprime bases.

## Contract

- Uses the unary scalar ABI: `int64_t carmichael_number(int64_t value)`.
- Inputs in `[1, 10,000]` are accepted. Values outside the range return `-1`.
- Return `1` for composite `n` when `b^(n-1) mod n == 1` for every `b` with `2 <= b < n` and `gcd(b,n) == 1`; otherwise return `0`.
- Values below 3, including 1 and 2, return `0`. Prime inputs return `0`.
- The source's modular exponentiation is retained, with an explicit compositeness check to make the result a Carmichael-number predicate. This rejects primes, which satisfy the Fermat congruence for every coprime base but are not Carmichael numbers.

## Source semantics

The benchmark is based on the pinned [TheAlgorithms Python `carmichael_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/carmichael_number.py). The source computes modular powers for every coprime base from 2 through `n-1`, using recursive exponentiation by squaring. Its `all()` predicate also returns true for primes, because every prime satisfies Fermat's little theorem; it even returns true for 1 and 2 because the range of bases is empty. The benchmark corrects this omission by requiring `n >= 3` and compositeness before applying the source's Fermat check. Nonpositive inputs raise in Python and map to `-1` in this scalar ABI. The 10,000 upper bound keeps the source-style per-base check bounded and includes the documented example 8911.

## Workload and build

[`workload.json`](workload.json) includes small boundaries, primes, ordinary composites, Carmichael numbers, and values near the upper bound. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm carmichael_number --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/carmichael_number/c/build.json
```

The nine implementations are in `c/c/carmichael_number.c`, `c3/c/carmichael_number.c3`, `cpp/c/carmichael_number.cpp`, `elisa/c/carmichael_number.elisa`, `nim/c/carmichael_number.nim`, `odin/c/carmichael_number.odin`, `rust/c/carmichael_number.rs`, `v/c/carmichael_number.v`, and `zig/c/carmichael_number.zig`.
