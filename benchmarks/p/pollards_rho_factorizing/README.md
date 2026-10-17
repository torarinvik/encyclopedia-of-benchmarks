# Pollard's rho factorizing

This benchmark preserves the deterministic seed and gcd return value of the pinned C# Pollard-rho implementation. It measures the source method's returned divisor, not a primality or factorization-quality claim.

## Contract

- The ABI is `scalar`: a signed-i64 input `n` in `2..46340` and a signed-i64 result. The ABI rejects inputs outside this bounded domain with `-1` before calling the source. The lower bound avoids modulo-by-zero and the source's nonterminating `n=1` case; the upper bound keeps signed 32-bit `x*x + 1` from overflowing.
- The source initializes `x = y = 2`, advances `x` once and `y` twice using `f(z) = (z*z + 1) % n`, and returns the first `gcd(abs(x-y), n)` that is not `1`. The source uses binary GCD, which agrees with the mathematical gcd for this positive domain.
- The returned value may equal `n`, including for primes and cases where the iteration finds no proper divisor. Ports must preserve that result instead of converting it to a prime/composite flag or requiring a proper factor. A valid call returns a value greater than `1`; the adapter uses `-1` for inputs outside the bounded domain.

The cases in [workload.json](workload.json) cover domain rejection, small primes and composites, perfect powers, semiprimes, results equal to the input, and the upper safe bound. The independent recurrence oracle is [pollards_rho_factorizing_oracle.py](../../pollards_rho_factorizing_oracle.py).

Pinned sources: [TheAlgorithms/C-Sharp `PollardsRhoFactorizing.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/PollardsRhoFactorizing.cs) and its [`BinaryGreatestCommonDivisorFinder.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/GreatestCommonDivisor/BinaryGreatestCommonDivisorFinder.cs), both at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family scalar --algorithm pollards_rho_factorizing --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/pollards_rho_factorizing/rust/build.json
python3 benchmarks/verify_scalar.py --algorithms pollards_rho_factorizing --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/p/pollards_rho_factorizing.c](../../../c/p/pollards_rho_factorizing.c) |
| C3 | [c3/p/pollards_rho_factorizing.c3](../../../c3/p/pollards_rho_factorizing.c3) |
| C++ | [cpp/p/pollards_rho_factorizing.cpp](../../../cpp/p/pollards_rho_factorizing.cpp) |
| Elisa | [elisa/p/pollards_rho_factorizing.elisa](../../../elisa/p/pollards_rho_factorizing.elisa) |
| Nim | [nim/p/pollards_rho_factorizing.nim](../../../nim/p/pollards_rho_factorizing.nim) |
| Odin | [odin/p/pollards_rho_factorizing.odin](../../../odin/p/pollards_rho_factorizing.odin) |
| Rust | [rust/p/pollards_rho_factorizing.rs](../../../rust/p/pollards_rho_factorizing.rs) |
| V | [v/p/pollards_rho_factorizing.v](../../../v/p/pollards_rho_factorizing.v) |
| Zig | [zig/p/pollards_rho_factorizing.zig](../../../zig/p/pollards_rho_factorizing.zig) |
