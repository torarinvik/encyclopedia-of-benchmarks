# Addition Without Arithmetic

This algorithm adds two signed integers by repeatedly combining non-carrying sum bits with shifted carry bits: XOR computes the sum bits and AND finds the carry.

## Contract

- Inputs are two signed 32-bit integers passed through the signed 64-bit scalar ABI.
- The exact sum is returned when both inputs and the result fit in signed 32-bit range.
- If either input is outside signed 32-bit range, or the exact sum overflows that range, the function returns `-1`.
- The algorithm uses fixed-width unsigned bit operations for its carry loop. Signed decoding and overflow detection are portable integer operations; no x86 or Intel-specific instructions are used.

## Workload and verification

[`workload.json`](workload.json) includes positive and negative operands, carry chains, signed boundaries, overflows, and out-of-range values. [`verify_binary_scalar.py`](../../verify_binary_scalar.py) compares all nine ports with the mathematical addition oracle over small input pairs, deterministic random pairs, and boundary combinations, then validates every recorder entry.

## Reviewed TheAlgorithms sources

- [C-Sharp `AdditionWithoutArithmetic.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/AdditionWithoutArithmetic.cs) — uses XOR for sum bits and AND followed by a left shift for carry bits over 32-bit integers.
- [Python `addition_without_arithmetic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/addition_without_arithmetic.py) — uses the same carry recurrence and supports negative integers.

The shared contract avoids platform-dependent overflow behavior by requiring the exact sum to fit signed 32-bit range. The local implementations return `-1` for overflow and reject operands outside that range; the upstream C-Sharp method itself wraps at its `int` width, while Python integers are unbounded.
