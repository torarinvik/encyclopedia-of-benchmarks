# Project Euler Problem 207: Integer Partition Equations

## Contract

The `float64_unary` function accepts a maximum proportion in `[1e-5, 1]`. It returns the smallest partition value `k` for which the proportion of perfect partitions among all partitions with values up to `k` is strictly below the threshold. The integral result is returned as binary64. Invalid thresholds return `-1e300`.

The pinned source scans candidates `(i² - 1) / 4` for increasing integer `i`. Only odd `i` produce valid integer partitions. Numbering those valid partitions by `r` gives candidate `k = r(r+1)`; the partition is perfect exactly when `r+1` is a power of two, equivalent to the source's integral `log2` check on this bounded domain. After each valid candidate, the ports update the perfect and total counts and compare their binary64 ratio with the threshold using a strict `<`. The search is bounded at 5,000,000 valid partitions; at that point the ratio is `22/5,000,000 < 1e-5`, so every accepted threshold has already stopped.

The source examples return `1.0 -> 6`, `0.5 -> 30`, and `3/13 -> 210`. The default threshold `1/12345` returns **44043947822**.

## Workload

[`workload.json`](workload.json) covers the documented proportions, the default threshold, invalid thresholds, and the strict comparison behavior. It uses one measured call because the default scans hundreds of thousands of valid partitions.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_207/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family float64_unary --algorithm problem207 --language rust

Run it with:

    python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/p/problem207/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem207.c](../../../c/p/problem207.c) |
| C3 | [c3/p/problem207.c3](../../../c3/p/problem207.c3) |
| C++ | [cpp/p/problem207.cpp](../../../cpp/p/problem207.cpp) |
| Elisa | [elisa/p/problem207.elisa](../../../elisa/p/problem207.elisa) |
| Nim | [nim/p/problem207.nim](../../../nim/p/problem207.nim) |
| Odin | [odin/p/problem207.odin](../../../odin/p/problem207.odin) |
| Rust | [rust/p/problem207.rs](../../../rust/p/problem207.rs) |
| V | [v/p/problem207.v](../../../v/p/problem207.v) |
| Zig | [zig/p/problem207.zig](../../../zig/p/problem207.zig) |
