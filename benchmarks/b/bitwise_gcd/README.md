# Bitwise GCD

Computes the greatest common divisor with Stein's binary algorithm, using trailing-zero removal and subtraction.

## Contract

- Uses the binary scalar ABI: `int64_t bitwise_gcd(uint64_t left, uint64_t right)`.
- Both inputs are in `[0, INT64_MAX]`; both zero returns zero. All workload inputs obey this domain.
- Returns the nonnegative greatest common divisor. The result always fits signed 64-bit for this input range.
- The implementation removes shared powers of two once, removes powers of two from the second operand each round, orders the odd operands, subtracts the smaller from the larger, and restores the shared power of two at the end.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `BitwiseGCD.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BitwiseGCD.java), specifically its two-argument `gcd(long, long)` implementation of Stein's algorithm. For nonnegative inputs, the source returns the exact GCD, including `gcd(0,0)=0`, and uses shifts and subtraction rather than Euclid's remainder step. This is distinct from the existing [`gcd`](../../g/gcd/README.md) benchmark, which uses Euclid's algorithm. The source also supports negative values and delegates `Long.MIN_VALUE` cases to BigInteger; the shared workload stays in the nonnegative signed-64 domain, so those branches are not included.

## Workload and build

[`workload.json`](workload.json) covers zero cases, shared powers of two, unequal odd parts, equal and coprime values, and signed-64 boundaries. Build and record with the binary scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm bitwise_gcd --language c
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/b/bitwise_gcd/c/build.json
```

The nine implementations are in `c/b/bitwise_gcd.c`, `c3/b/bitwise_gcd.c3`, `cpp/b/bitwise_gcd.cpp`, `elisa/b/bitwise_gcd.elisa`, `nim/b/bitwise_gcd.nim`, `odin/b/bitwise_gcd.odin`, `rust/b/bitwise_gcd.rs`, `v/b/bitwise_gcd.v`, and `zig/b/bitwise_gcd.zig`.
