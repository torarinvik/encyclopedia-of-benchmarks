# Bitwise complement

This benchmark complements the significant binary digits of a nonnegative integer. It ignores leading zero bits: for example, `5` (`101₂`) maps to `2` (`010₂`). Zero maps to one.

## Contract

- The scalar input must be in the range 0 through `INT32_MAX`; other signed 64-bit inputs return `-1`.
- For positive `n`, return `n XOR ((1 << bit_length(n)) - 1)`. Return `1` for zero.
- The implementation finds the bit length with portable integer shifts. It uses no floating-point logarithm and no architecture-specific instructions.

The pinned C sources use two equivalent strategies: C LeetCode 1009 estimates bit length with `ceil(log2(n))`, while C LeetCode 476 constructs a mask from the most significant bit. The shared implementation handles zero explicitly and stays within the source problem's signed 32-bit input domain.

## Workload and verification

`workload.json` includes zero, individual low values, powers of two, the largest signed 32-bit input, negative input, and values outside the supported domain. Build with `python3 benchmarks/build_scalar.py --algorithm bitwise_complement --language LANGUAGE`. `python3 benchmarks/verify_scalar.py --algorithms bitwise_complement` checks a dense input range, deterministic boundary and random values, and the recorder.

## TheAlgorithms sources

- [C LeetCode 1009](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1009.c)
- [C LeetCode 476](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/476.c)
