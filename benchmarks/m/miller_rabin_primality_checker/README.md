# Miller–Rabin primality checker

This benchmark follows the pinned C# [`MillerRabinPrimalityChecker`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/MillerRabinPrimalityChecker.cs). The source performs a strong probable-prime test and draws one witness before its rounds loop, then reuses that witness for every round.

## Contract

The `i64_array_scalar` input is exactly `[n, rounds, seed]`; the array length is supplied separately and there is no count prefix. Valid inputs have odd `n` in `5..=2,147,483,647`, `rounds` in `1..=64`, and `seed` in `0..=2,147,483,647`. All other shapes and values return `-1`. Valid calls return `1` when the selected witness passes every round, and `0` when it proves the number composite.

To make the optional source seed portable across the nine implementation languages, the benchmark normalizes the source's random choice to the repository's SplitMix64 generator. Initialize its unsigned 64-bit state from `seed`; each word adds `0x9E3779B97F4A7C15` modulo `2^64`, then applies the xor-shift/multiply steps with `0xBF58476D1CE4E5B9` and `0x94D049BB133111EB`, also modulo `2^64`, and returns the final xor-shifted word. Let `span = n - 4`; for an unbiased value in `[0, span)`, reject words below `2^64 mod span` and otherwise use `word mod span`. Select `a = 2 + value`, consuming a word even when `span` is one. Draw one accepted witness per call and reuse it for all rounds, matching the pinned source's control flow rather than selecting a new base each round.

The odd-only domain follows the source's stated precondition. In particular, it avoids treating its even-input behavior as a primality guarantee. The repeated-witness behavior is observable: `n=65, seed=14` selects `a=8`, a strong liar for 65, so the source-normalized result is `1` even for 64 rounds. With `seed=75`, the selected witness is `a=2` and the result is `0`. Modular products fit signed 64-bit arithmetic because `n` is at most `2,147,483,647`.

The independent oracle is [`miller_rabin_primality_checker_oracle.py`](../../miller_rabin_primality_checker_oracle.py). The fixed-base [`miller_rabin`](../miller_rabin/README.md) benchmark is a separate contract: it fixes four witnesses and guarantees a deterministic classification throughout its domain, whereas this benchmark preserves one seeded, reused witness.

## Workload and build

[`workload.json`](workload.json) includes the minimum valid odd prime, the repeated-witness liar and rejector cases, the largest signed 32-bit prime, and invalid domain/shape cases.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm miller_rabin_primality_checker --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/m/miller_rabin_primality_checker/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms miller_rabin_primality_checker --languages rust
```

