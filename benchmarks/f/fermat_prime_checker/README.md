# Fermat prime checker

This benchmark ports the pinned C# `FermatPrimeChecker.IsPrime` routine as a deterministic, bounded Fermat probable-prime check.

## Contract

- The `binary_scalar` input is `[numberToTest, timesToCheck]`; valid values are `numberToTest` in `2..=1,000,000` and `timesToCheck` in `2..=64`.
- Return `1` when every Fermat congruence passes, `0` when any sampled base witnesses compositeness, and `-1` for inputs outside those bounds.
- The source seeds `Random` with `default(DateTime).Millisecond`, which is always zero. The ports reproduce the legacy seeded .NET subtractive `Random(0)` stream and `Random.Next(1, numberToTest)` range mapping.
- The source initializes `iterator` to 1 and loops while `iterator < timesToCheck`; therefore the number of modular exponentiation checks is `timesToCheck - 1`. The benchmark preserves this off-by-one behavior while excluding `timesToCheck <= 1`, where the source would return true without checking any base.
- Modular exponentiation uses exponent `numberToTest - 1`. This remains bounded by the chosen input cap; products in the ports use a sufficiently wide integer type.
- This is a probable-prime checker, not a proof of primality. Carmichael numbers and other pseudoprimes can pass if the deterministic sampled bases are all liars.

The independent oracle is [`fermat_prime_checker_oracle.py`](../../fermat_prime_checker_oracle.py). The workload includes prime and composite inputs, seeded Carmichael/pseudoprime cases, bounds, and the source's one-check-per-call behavior.

## Pinned source

- [TheAlgorithms/C-Sharp `Algorithms/Other/FermatPrimeChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/FermatPrimeChecker.cs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm fermat_prime_checker --language rust
python3 benchmarks/run_binary_scalar.py --algorithm fermat_prime_checker
python3 benchmarks/verify_binary_scalar.py --algorithms fermat_prime_checker
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fermat_prime_checker.c`](../../../c/f/fermat_prime_checker.c) |
| C3 | [`c3/f/fermat_prime_checker.c3`](../../../c3/f/fermat_prime_checker.c3) |
| C++ | [`cpp/f/fermat_prime_checker.cpp`](../../../cpp/f/fermat_prime_checker.cpp) |
| Elisa | [`elisa/f/fermat_prime_checker.elisa`](../../../elisa/f/fermat_prime_checker.elisa) |
| Nim | [`nim/f/fermat_prime_checker.nim`](../../../nim/f/fermat_prime_checker.nim) |
| Odin | [`odin/f/fermat_prime_checker.odin`](../../../odin/f/fermat_prime_checker.odin) |
| Rust | [`rust/f/fermat_prime_checker.rs`](../../../rust/f/fermat_prime_checker.rs) |
| V | [`v/f/fermat_prime_checker.v`](../../../v/f/fermat_prime_checker.v) |
| Zig | [`zig/f/fermat_prime_checker.zig`](../../../zig/f/fermat_prime_checker.zig) |
