# Project Euler Problem 493: Under The Rainbow

## Contract

For a pick count from 0 through 70, return the expected number of distinct colours from drawing that many balls without replacement from seven colours with ten balls each. The pinned Python source formats the expectation to nine digits after the decimal point. The scalar ABI stores that formatted decimal losslessly as an integer scaled by 1,000,000,000; for example, the source output `6.818741802` is returned as `6818741802`. Counts outside 0..70 return -1.

The ports preserve the source's probability calculation. By symmetry, the probability one colour is absent is `C(70-picks, 10) / C(70, 10)` for picks <= 60 and zero otherwise. The expectation is seven times one minus that probability. Integer decimal digit generation and nearest-even rounding produce the same nine-place outputs as the pinned Python formatting for every supported pick count, while keeping intermediate values within signed 64-bit arithmetic.

The source examples are 5.669644129 for 10 picks and 6.985042712 for 30 picks. The canonical 20-pick output is **6.818741802** (scaled result **6818741802**).

## Workload

[`workload.json`](workload.json) covers the source examples, zero and boundary picks, the canonical input, and invalid bounds. Expected results use the scaled integer representation described above.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_493/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem493.c](../../../c/p/problem493.c) |
| C3 | [c3/p/problem493.c3](../../../c3/p/problem493.c3) |
| C++ | [cpp/p/problem493.cpp](../../../cpp/p/problem493.cpp) |
| Elisa | [elisa/p/problem493.elisa](../../../elisa/p/problem493.elisa) |
| Nim | [nim/p/problem493.nim](../../../nim/p/problem493.nim) |
| Odin | [odin/p/problem493.odin](../../../odin/p/problem493.odin) |
| Rust | [rust/p/problem493.rs](../../../rust/p/problem493.rs) |
| V | [v/p/problem493.v](../../../v/p/problem493.v) |
| Zig | [zig/p/problem493.zig](../../../zig/p/problem493.zig) |
