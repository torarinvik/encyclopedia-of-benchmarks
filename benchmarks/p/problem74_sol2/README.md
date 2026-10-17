# Project Euler Problem 74, solution 2

This benchmark ports the second source implementation of Project Euler 74. It counts start values whose source-computed digit-factorial chain has the requested number of distinct terms. The contract keeps this implementation separate from [`problem74`](../problem74/README.md): the pinned source's documented call `solution(10, 1000)` returns 26, while solution 1 returns 28.

## Contract

The function accepts two signed 64-bit integers, `[chain_length, number_limit]`. Both must be positive. `chain_length` is bounded to 1 through 60, and `number_limit` is bounded to 1 through 1,000,000. Invalid values return `-1`.

The source scans start values in ascending order from 1 up to, but not including, `number_limit`. For each start it repeatedly sums the factorials of its decimal digits, treating zero as `0! = 1`. The source keeps a fresh set of terms for that start and a map of chain lengths cached for earlier starts. It stops when it reaches a cached value, repeats a term, or the distinct-term count exceeds the requested length. It counts the start only when the resulting source chain length equals `chain_length`.

The caller supplies the two values directly through the binary scalar ABI. The benchmark does not include Project Euler's prose, command-line output, or the alternative solution 1 implementation.

## Pinned source

[TheAlgorithms/Python `project_euler/problem_074/sol2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_074/sol2.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, function `solution`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/problem74_sol2.c`](../../../c/p/problem74_sol2.c) |
| C3 | [`c3/p/problem74_sol2.c3`](../../../c3/p/problem74_sol2.c3) |
| C++ | [`cpp/p/problem74_sol2.cpp`](../../../cpp/p/problem74_sol2.cpp) |
| Elisa | [`elisa/p/problem74_sol2.elisa`](../../../elisa/p/problem74_sol2.elisa) |
| Nim | [`nim/p/problem74_sol2.nim`](../../../nim/p/problem74_sol2.nim) |
| Odin | [`odin/p/problem74_sol2.odin`](../../../odin/p/problem74_sol2.odin) |
| Rust | [`rust/p/problem74_sol2.rs`](../../../rust/p/problem74_sol2.rs) |
| V | [`v/p/problem74_sol2.v`](../../../v/p/problem74_sol2.v) |
| Zig | [`zig/p/problem74_sol2.zig`](../../../zig/p/problem74_sol2.zig) |
