# Project Euler Problem 587: Concave Triangle

## Contract

The `float64_unary` function accepts a target area fraction in `[0.001, 0.1]`. It returns the least positive circle count `n` for which the concave triangle area divided by the L-section area is strictly below the target. The integral result is returned as binary64. Invalid thresholds return `-1e300`.

The ports preserve the pinned source's geometric formulas and search order. The L-section area is `(1 - pi/4)/4`; the intersection is computed from `y = (n + 1 - sqrt(2n)) / (2(n² + 1))`, `x = n*y`; the concave area adds `x*y/2` to the difference between bottom-arc integrals at `1/2` and `x`. The source's default threshold `0.001` returns **2240**; its documented example `0.1` returns **15**. The adapter scans through at most 100,000 circles.

## Workload

[`workload.json`](workload.json) covers the documented example, canonical default, and invalid thresholds. It uses one measured call because each input searches sequentially from `n=1`.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_587/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family float64_unary --algorithm problem587 --language rust

Run it with:

    python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/p/problem587/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem587.c](../../../c/p/problem587.c) |
| C3 | [c3/p/problem587.c3](../../../c3/p/problem587.c3) |
| C++ | [cpp/p/problem587.cpp](../../../cpp/p/problem587.cpp) |
| Elisa | [elisa/p/problem587.elisa](../../../elisa/p/problem587.elisa) |
| Nim | [nim/p/problem587.nim](../../../nim/p/problem587.nim) |
| Odin | [odin/p/problem587.odin](../../../odin/p/problem587.odin) |
| Rust | [rust/p/problem587.rs](../../../rust/p/problem587.rs) |
| V | [v/p/problem587.v](../../../v/p/problem587.v) |
| Zig | [zig/p/problem587.zig](../../../zig/p/problem587.zig) |
