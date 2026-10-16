# wine_problem_memoized

This package benchmarks the pinned Java `WineProblem.wptd` top-down dynamic-programming method. Each subproblem stores the best revenue for a remaining interval; recursive choices still sell only the leftmost or rightmost wine.

## Contract

- Input is a signed i64 array of 1 to 64 wine prices, each from 1 through 1,000,000.
- A wine sold in year `y` earns `price * y`, starting at year 1. The result is the maximum revenue over all left/right sale sequences.
- The source uses zero as its memo-table sentinel. Requiring positive prices ensures every valid subproblem has a nonzero result and is cached, preserving the top-down O(n²) behavior. The maximum result, 2,080,000,000, fits the Java `int` result type.
- Invalid length or price values return `-1`.

The oracle uses bottom-up interval dynamic programming. The workload includes the source example, cached subproblems, the 64-item bound, and invalid inputs.

Pinned source: [TheAlgorithms/Java `WineProblem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/WineProblem.java).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm wine_problem_memoized --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_scalar.py --algorithm wine_problem_memoized

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/wine_problem_memoized.c](../../../c/w/wine_problem_memoized.c) |
| C3 | [c3/w/wine_problem_memoized.c3](../../../c3/w/wine_problem_memoized.c3) |
| C++ | [cpp/w/wine_problem_memoized.cpp](../../../cpp/w/wine_problem_memoized.cpp) |
| Elisa | [elisa/w/wine_problem_memoized.elisa](../../../elisa/w/wine_problem_memoized.elisa) |
| Nim | [nim/w/wine_problem_memoized.nim](../../../nim/w/wine_problem_memoized.nim) |
| Odin | [odin/w/wine_problem_memoized.odin](../../../odin/w/wine_problem_memoized.odin) |
| Rust | [rust/w/wine_problem_memoized.rs](../../../rust/w/wine_problem_memoized.rs) |
| V | [v/w/wine_problem_memoized.v](../../../v/w/wine_problem_memoized.v) |
| Zig | [zig/w/wine_problem_memoized.zig](../../../zig/w/wine_problem_memoized.zig) |
