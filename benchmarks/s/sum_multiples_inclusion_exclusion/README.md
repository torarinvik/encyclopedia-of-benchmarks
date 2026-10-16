# Sum multiples with inclusion-exclusion

Return the sum of all positive integers strictly below `limit` that are divisible by 3 or 5, using arithmetic-series inclusion-exclusion.

## Contract

- Input is a signed 64-bit integer `limit` in `1..=100,000`.
- Return the sum of positive multiples of 3 plus the sum of positive multiples of 5, minus the sum of positive multiples of 15, all strictly below `limit`.
- Inputs outside the supported range return `-1`.
- The formula uses constant time and constant extra space. Intermediate values stay within signed 64-bit range for the supported domain.

For divisor `d`, the contribution is `d * k * (k + 1) / 2`, where `k = floor((limit - 1) / d)`. The strict limit makes `limit == d` contribute no multiple of `d`.

This is kept separately from [`problem1`](../../p/problem1/README.md), whose ports use a direct scan. Both return the same mathematical result on their shared domain; this package preserves the formula-based method present in the pinned C and Dart sources.

## Workload and verification

The workload covers strict boundaries, overlaps at multiples of 15, the canonical result below 1,000, the upper bound, and invalid inputs. `verify_scalar.py` compares the ports with a direct-scan prefix oracle.

Run all nine implementations with:

```sh
python3 benchmarks/verify_scalar.py --algorithm sum_multiples_inclusion_exclusion
```

## TheAlgorithms sources

- [C `sol1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_1/sol1.c)
- [Dart `sol1.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/project_euler/problem_1/sol1.dart)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/sum_multiples_inclusion_exclusion.c](../../../c/s/sum_multiples_inclusion_exclusion.c) |
| C3 | [c3/s/sum_multiples_inclusion_exclusion.c3](../../../c3/s/sum_multiples_inclusion_exclusion.c3) |
| C++ | [cpp/s/sum_multiples_inclusion_exclusion.cpp](../../../cpp/s/sum_multiples_inclusion_exclusion.cpp) |
| Elisa | [elisa/s/sum_multiples_inclusion_exclusion.elisa](../../../elisa/s/sum_multiples_inclusion_exclusion.elisa) |
| Nim | [nim/s/sum_multiples_inclusion_exclusion.nim](../../../nim/s/sum_multiples_inclusion_exclusion.nim) |
| Odin | [odin/s/sum_multiples_inclusion_exclusion.odin](../../../odin/s/sum_multiples_inclusion_exclusion.odin) |
| Rust | [rust/s/sum_multiples_inclusion_exclusion.rs](../../../rust/s/sum_multiples_inclusion_exclusion.rs) |
| V | [v/s/sum_multiples_inclusion_exclusion.v](../../../v/s/sum_multiples_inclusion_exclusion.v) |
| Zig | [zig/s/sum_multiples_inclusion_exclusion.zig](../../../zig/s/sum_multiples_inclusion_exclusion.zig) |
