# LCM sum

This benchmark computes

`LCM(1, n) + LCM(2, n) + ... + LCM(n, n)`

using the Euler totient identity. The algorithm is stored under `benchmarks/l/lcm_sum/` by its name.

## Contract

- The input `n` is a signed 64-bit integer in `1..=65535`.
- Inputs outside this range return `-1`.
- The result is the exact sum of the least common multiples from `1` through `n`; it fits in signed 64-bit for this input range.

TheAlgorithms C++ references use the identity `n * (1 + sum(d * phi(d) for d dividing n)) / 2` after building Euler's totient values with a sieve. The nine local ports evaluate the same identity by enumerating divisor pairs and calculating each needed totient by factorization. This keeps the C ABI call allocation-free and uses ordinary integer arithmetic on each platform.

## Workload

`workload.json` includes the upstream examples `2`, `5`, `10`, `11`, and `15`, small values, prime and power-of-two inputs, the maximum input, and invalid boundaries. The verifier adds every input from `-8` through `512`, deterministic random values, and the full input boundaries. Its oracle directly sums `i / gcd(i, n) * n`, independently of the totient identity used by the ports.

## Run

Build and record with the standard unary scalar ABI. `benchmarks/verify_scalar.py --algorithms lcm_sum` compiles and checks all nine language ports against the direct GCD-based oracle.
