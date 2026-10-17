# Project Euler problem 2 (`so1`)

## Contract

The input is one signed 64-bit threshold. For thresholds from `-2,147,483,648` through `1,000,000,000`, return the sum of even-valued Fibonacci terms that are at most the threshold, starting with the sequence `1, 2, 3, 5, 8, ...`. A valid negative threshold returns zero. Inputs outside the supported range return `-1`.

The upper bound keeps the pinned C program's `int` Fibonacci updates and sum within signed 32-bit range. At the maximum threshold, the last computed next term is `1,134,903,170`, and the even-term sum is `350,704,366`.

## Source behavior

The benchmark follows the pinned [TheAlgorithms C `so1.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_2/so1.c). The source reads one `%d` threshold, initializes the pair to `(1, 2)`, adds the second term when it is even and no greater than the threshold, then advances the pair. The ports expose that computation as a scalar function.

The independent oracle advances the even Fibonacci subsequence directly (`2, 8, 34, ...`) rather than using the source's full pair recurrence.

## Workload and verification

[`workload.json`](workload.json) covers thresholds below and at the first even terms, the published four-million example, source-integer limits, the benchmark upper bound, and out-of-range signed 64-bit values. Verify with `python3 benchmarks/verify_scalar.py --algorithms so1`.

## Implementations

The nine portable implementations use the shared `scalar_call` ABI.

| Language | Source |
| --- | --- |
| C | [`c/s/so1.c`](../../../c/s/so1.c) |
| C3 | [`c3/s/so1.c3`](../../../c3/s/so1.c3) |
| C++ | [`cpp/s/so1.cpp`](../../../cpp/s/so1.cpp) |
| Elisa | [`elisa/s/so1.elisa`](../../../elisa/s/so1.elisa) |
| Nim | [`nim/s/so1.nim`](../../../nim/s/so1.nim) |
| Odin | [`odin/s/so1.odin`](../../../odin/s/so1.odin) |
| Rust | [`rust/s/so1.rs`](../../../rust/s/so1.rs) |
| V | [`v/s/so1.v`](../../../v/s/so1.v) |
| Zig | [`zig/s/so1.zig`](../../../zig/s/so1.zig) |
