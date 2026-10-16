# wine_problem_tabulated

This package benchmarks the pinned Java `WineProblem.wpbu` bottom-up tabulation method. It fills the interval table from shorter spans to longer spans, taking the better of selling the leftmost or rightmost remaining wine.

## Contract

- Input is a signed i64 array of 1 to 64 wine prices, each from 0 through 1,000,000.
- A wine sold in year `y` earns `price * y`, starting at year 1. The result is the maximum revenue over all left/right sale sequences.
- The implementation preserves the source's O(n²) tabulation order. The 64-item bound keeps the maximum result, 2,080,000,000, within the Java `int` result type.
- Invalid length or price values return `-1`.

The oracle uses top-down interval memoization. The workload includes the source example, zero prices, the 64-item bound, and invalid inputs.

Pinned source: [TheAlgorithms/Java `WineProblem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/WineProblem.java).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm wine_problem_tabulated --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_scalar.py --algorithm wine_problem_tabulated

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/wine_problem_tabulated.c](../../../c/w/wine_problem_tabulated.c) |
| C3 | [c3/w/wine_problem_tabulated.c3](../../../c3/w/wine_problem_tabulated.c3) |
| C++ | [cpp/w/wine_problem_tabulated.cpp](../../../cpp/w/wine_problem_tabulated.cpp) |
| Elisa | [elisa/w/wine_problem_tabulated.elisa](../../../elisa/w/wine_problem_tabulated.elisa) |
| Nim | [nim/w/wine_problem_tabulated.nim](../../../nim/w/wine_problem_tabulated.nim) |
| Odin | [odin/w/wine_problem_tabulated.odin](../../../odin/w/wine_problem_tabulated.odin) |
| Rust | [rust/w/wine_problem_tabulated.rs](../../../rust/w/wine_problem_tabulated.rs) |
| V | [v/w/wine_problem_tabulated.v](../../../v/w/wine_problem_tabulated.v) |
| Zig | [zig/w/wine_problem_tabulated.zig](../../../zig/w/wine_problem_tabulated.zig) |
