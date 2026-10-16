# Bitwise complement

This benchmark complements the significant binary digits of a nonnegative integer. It ignores leading zero bits: for example, `5` (`101₂`) maps to `2` (`010₂`). Zero maps to one.

## Contract

- The scalar input must be in the range 0 through 999,999,999, matching the pinned LeetCode 1009 input constraint; other signed 64-bit inputs return `-1`.
- For positive `n`, return `n XOR ((1 << bit_length(n)) - 1)`. Return `1` for zero.
- The implementation finds the bit length with portable integer shifts. It uses no floating-point logarithm and no architecture-specific instructions.

The pinned C LeetCode 1009 source estimates a mask width with `ceil(log2(n))`, while C LeetCode 476 counts through the most significant bit. For `n = 2^k`, the 1009 estimate is `k` rather than the `k + 1` significant-bit width, but its final result still matches the standard complement: the omitted high bit is set in `n`, so `(~n) & (2^k - 1) = 2^k - 1` (for example, `4 -> 3` and `1024 -> 1023`). For positive non-powers of two, `ceil(log2(n))` equals the significant-bit width. The benchmark keeps the standard problem outputs and the pinned 1009 input domain `0 <= n < 1,000,000,000`, where the source's signed shift is defined.

## Workload and verification

`workload.json` includes zero, individual low values, powers of two, the largest supported input, negative input, and values at or above the excluded upper boundary. Build with `python3 benchmarks/build_scalar.py --algorithm bitwise_complement --language LANGUAGE`. `python3 benchmarks/verify_scalar.py --algorithms bitwise_complement` checks a dense input range, deterministic boundary and random values, and the recorder.

## TheAlgorithms sources

- [C LeetCode 1009](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1009.c)
- [C LeetCode 476](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/476.c)
