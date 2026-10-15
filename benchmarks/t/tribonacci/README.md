# Tribonacci number

This benchmark returns the zero-based Tribonacci number with `T(0) = 0`, `T(1) = 1`, `T(2) = 1`, and `T(n) = T(n - 1) + T(n - 2) + T(n - 3)`.

## Contract

- The scalar input `n` is supported from 0 through 73. The function returns the exact signed 64-bit result in this range and `-1` otherwise.
- `T(73)` is the largest result that fits in a signed 64-bit integer; `T(74)` overflows that result type.
- The implementation uses a constant-space iterative recurrence and portable integer addition.

The C, Java, and JavaScript nth-number implementations agree on these initial values. The C source's original 32-bit interface supports a smaller range; this benchmark defines a shared signed 64-bit range. The Python file named `tribonacci.py` instead emits the first `n` elements beginning `0, 0, 1`, so it is documented as a semantic mismatch. The C# `TribonacciNumbersSequence` uses `1, 1, 1` and remains a separate sequence candidate.

## Workload and verification

`workload.json` includes the initial terms, representative positions, the largest signed 64-bit result, and out-of-range inputs. Build with `python3 benchmarks/build_scalar.py --algorithm tribonacci --language LANGUAGE`. `python3 benchmarks/verify_scalar.py --algorithms tribonacci` checks every supported input against an independent recurrence oracle and exercises the recorder.

## TheAlgorithms sources

- [C LeetCode 1137](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1137.c)
- [Java Tribonacci](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/Tribonacci.java)
- [JavaScript TribonacciNumber](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/TribonacciNumber.js)
- [Python sequence variant](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/tribonacci.py)
- [C# `1, 1, 1` sequence variant](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/TribonacciNumbersSequence.cs)
