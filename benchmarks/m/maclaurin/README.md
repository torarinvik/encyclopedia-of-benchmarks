# Maclaurin error-threshold series

The pinned C# `Maclaurin` class offers fixed-term and threshold-driven overloads for exponential, sine, and cosine series. The fixed-term sine/cosine family is covered by `maclaurin_series`, and the fixed-term exponential family by `exponential_function`; this benchmark isolates the C# `ErrorTermWrapper` behavior.

## Contract

Input is `[mode, x_milli, error_milli]`: mode 0 is `Exp`, 1 is `Sin`, and 2 is `Cos`; `x_milli` is in `[-2000,2000]` and `error_milli` in `[1,250]`, representing `x` and the error threshold in thousandths. The source wrapper initializes both the accumulated result and term coefficient to zero, then adds the prior coefficient before calculating the next indexed term. It stops once the newly calculated term has magnitude at most the threshold, so that final below-threshold term is not added. This preserves the source's zero result for cases where the first term already meets the threshold. Invalid inputs return `-1e300`.

The bounds ensure convergence with small factorial arguments. Output uses binary64 with absolute and relative tolerance `1e-12`. See [workload](workload.json), [oracle](../../maclaurin_oracle.py), and the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Numeric/Series/Maclaurin.cs).

| Language | Port |
|---|---|
| C | c/m/maclaurin.c |
| C3 | c3/m/maclaurin.c3 |
| C++ | cpp/m/maclaurin.cpp |
| Elisa | elisa/m/maclaurin.elisa |
| Nim | nim/m/maclaurin.nim |
| Odin | odin/m/maclaurin.odin |
| Rust | rust/m/maclaurin.rs |
| V | v/m/maclaurin.v |
| Zig | zig/m/maclaurin.zig |
