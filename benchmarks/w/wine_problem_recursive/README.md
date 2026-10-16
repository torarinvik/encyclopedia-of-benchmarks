# wine_problem_recursive

This package benchmarks the direct recursive `wpRecursion` method in the pinned Java `WineProblem` class. It maximizes revenue by selling only the leftmost or rightmost remaining wine each year. The memoized and tabulated methods in the same source file are separate algorithms and are not measured here.

## Contract

- Input is a signed i64 array of 1 to 14 wine prices, each from 0 through 1,000,000.
- A wine sold in year `y` earns `price * y`, with the first sale in year 1. The result is the greatest total revenue over all valid left/right sale sequences.
- The implementation preserves the source's uncached recursive recurrence. The 14-item bound keeps its exponential call tree practical and keeps the maximum result within signed 32-bit range, as in the Java source.
- Invalid length or price values return `-1`.

The independent oracle uses bottom-up interval dynamic programming to calculate the same recurrence. The workload includes the source's classic example, ties, zero prices, maximum input length, and invalid inputs.

Pinned source: [TheAlgorithms/Java `WineProblem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/WineProblem.java).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm wine_problem_recursive --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_scalar.py --algorithm wine_problem_recursive

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/wine_problem_recursive.c](../../../c/w/wine_problem_recursive.c) |
| C3 | [c3/w/wine_problem_recursive.c3](../../../c3/w/wine_problem_recursive.c3) |
| C++ | [cpp/w/wine_problem_recursive.cpp](../../../cpp/w/wine_problem_recursive.cpp) |
| Elisa | [elisa/w/wine_problem_recursive.elisa](../../../elisa/w/wine_problem_recursive.elisa) |
| Nim | [nim/w/wine_problem_recursive.nim](../../../nim/w/wine_problem_recursive.nim) |
| Odin | [odin/w/wine_problem_recursive.odin](../../../odin/w/wine_problem_recursive.odin) |
| Rust | [rust/w/wine_problem_recursive.rs](../../../rust/w/wine_problem_recursive.rs) |
| V | [v/w/wine_problem_recursive.v](../../../v/w/wine_problem_recursive.v) |
| Zig | [zig/w/wine_problem_recursive.zig](../../../zig/w/wine_problem_recursive.zig) |
