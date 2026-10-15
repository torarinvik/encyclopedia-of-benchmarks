# Newton integer square root

Returns the floor of the square root of a nonnegative integer using the pinned Newton iteration.

## Contract

- Uses the unary signed 64-bit scalar ABI.
- Inputs from 0 through 4,611,686,018,427,387,903 (`2^62 - 1`) are accepted. Zero returns zero; negative values and values above the bound return `-1` as the benchmark's out-of-domain sentinel.
- For positive `n`, the seed is `1 << (ceil(log2(n)) / 2)`, with integer division. Each Newton step computes `root = (root + n / root) / 2` using truncating integer division.
- The loop stops exactly when `root*root <= n <= root*root + 2*root`, which identifies `floor(sqrt(n))`.
- The bound keeps the root, its square, and the stopping-interval arithmetic within signed 64-bit range. It also bounds the logarithm seed computation to a range where binary64 precision is sufficient for this iteration.

## Source semantics

This follows pinned [TheAlgorithms C-Sharp `NewtonSquareRoot.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/NewtonSquareRoot.cs). The source throws for negative `BigInteger` inputs and returns zero before computing a seed for input zero. For positive values it uses `ceil(BigInteger.Log(n, 2))`, shifts one left by half that exponent, then repeats the integer Newton update until `IsSquareRoot` sees the inclusive interval from `root²` through `root² + root + root`. Near powers of two, its logarithm-derived seed can be rounded to the adjacent exponent; this only changes the starting estimate, while integer updates and the exact interval decide the result. The benchmark maps source exceptions and values above its safe ABI bound to `-1`.

## Workload and build

[`workload.json`](workload.json) covers zero, perfect squares and nearby values, powers of two, the signed-64-bit-safe upper bound, and invalid inputs.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm newton_square_root --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/n/newton_square_root/rust/build.json
```

The implementations are in `c/n/newton_square_root.c`, `c3/n/newton_square_root.c3`, `cpp/n/newton_square_root.cpp`, `elisa/n/newton_square_root.elisa`, `nim/n/newton_square_root.nim`, `odin/n/newton_square_root.odin`, `rust/n/newton_square_root.rs`, `v/n/newton_square_root.v`, and `zig/n/newton_square_root.zig`.
