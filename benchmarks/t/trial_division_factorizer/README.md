# Trial division factorizer

This benchmark ports the C# `TrialDivisionFactorizer.TryFactor` operation. It returns the first nontrivial factor found by checking divisors in ascending order.

## Contract

Input is one signed 64-bit scalar. Values in the signed int32 range are supported except `0` and `INT32_MIN`; all other inputs return `-1`. The excluded values are outside the source operation's defined behavior (`Math.Abs(0)` leads to an invalid range count, and `Math.Abs(INT32_MIN)` overflows).

For valid input, the operation checks the absolute value and returns its smallest factor from 2 through the integer square root, inclusive. If no factor is found, it returns `0`. This includes `1` and `-1`, which have no nontrivial factor even though they are not prime. Negative composites return a positive factor.

[`workload.json`](workload.json) covers units, positive and negative values, prime values, composites, perfect squares, int32 boundaries, and invalid inputs. The independent oracle is [`trial_division_factorizer_oracle.py`](../../trial_division_factorizer_oracle.py).

Pinned source: [TheAlgorithms/C-Sharp `TrialDivisionFactorizer.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Factorization/TrialDivisionFactorizer.cs).

Build one port with `python3 benchmarks/build_scalar.py --algorithm trial_division_factorizer --language LANGUAGE`. Implementations use the standard signed 64-bit scalar ABI.

## Implementations

| Language | Port |
|---|---|
| C | [`c/t/trial_division_factorizer.c`](../../../c/t/trial_division_factorizer.c) |
| C3 | [`c3/t/trial_division_factorizer.c3`](../../../c3/t/trial_division_factorizer.c3) |
| C++ | [`cpp/t/trial_division_factorizer.cpp`](../../../cpp/t/trial_division_factorizer.cpp) |
| Elisa | [`elisa/t/trial_division_factorizer.elisa`](../../../elisa/t/trial_division_factorizer.elisa) |
| Nim | [`nim/t/trial_division_factorizer.nim`](../../../nim/t/trial_division_factorizer.nim) |
| Odin | [`odin/t/trial_division_factorizer.odin`](../../../odin/t/trial_division_factorizer.odin) |
| Rust | [`rust/t/trial_division_factorizer.rs`](../../../rust/t/trial_division_factorizer.rs) |
| V | [`v/t/trial_division_factorizer.v`](../../../v/t/trial_division_factorizer.v) |
| Zig | [`zig/t/trial_division_factorizer.zig`](../../../zig/t/trial_division_factorizer.zig) |
