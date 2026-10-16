# Project Euler Problem 23

## Contract

For an inclusive limit from 0 through 28,123, return the sum of the positive integers up to that limit that cannot be written as the sum of two positive abundant numbers. A positive integer is abundant when the sum of its proper positive divisors exceeds it. A limit outside the supported range returns -1.

The ports build proper-divisor sums with a sieve, identify abundant values, mark pair sums, and add the unmarked values. The canonical limit returns 4,179,871. Inputs below 12 have no abundant values; 24 is the first representable sum because 12 is the smallest abundant number.

## Source review

The pinned Python solution and C sol1 both use an inclusive upper limit. The Python implementation adds each newly discovered abundant value before checking the current number, so an abundant value may pair with itself. C sol1 searches abundant complements through the inclusive limit.

C sol2 is the packed-bit lookup variant of the same intended algorithm. It sums only values strictly below its limit and allocates MAX_N >> 3 bytes while indexing through MAX_N >> 3, which can write past the allocated final byte. The shared contract follows the inclusive Python/C-sol1 behavior and bounds the input at the canonical 28,123 limit.

## Workload

The workload covers zero, values below the first abundant number, the first abundant value, the first abundant pair sum, intermediate bounds, the canonical limit, and invalid bounds.

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family scalar --algorithm problem23 --language rust

Run it with:

    python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem23/rust/build.json

## TheAlgorithms references

- Python sol1: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_023/sol1.py
- C sol1: https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_23/sol1.c
- C sol2: https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/project_euler/problem_23/sol2.c

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem23.c](../../../c/p/problem23.c) |
| C3 | [c3/p/problem23.c3](../../../c3/p/problem23.c3) |
| C++ | [cpp/p/problem23.cpp](../../../cpp/p/problem23.cpp) |
| Elisa | [elisa/p/problem23.elisa](../../../elisa/p/problem23.elisa) |
| Nim | [nim/p/problem23.nim](../../../nim/p/problem23.nim) |
| Odin | [odin/p/problem23.odin](../../../odin/p/problem23.odin) |
| Rust | [rust/p/problem23.rs](../../../rust/p/problem23.rs) |
| V | [v/p/problem23.v](../../../v/p/problem23.v) |
| Zig | [zig/p/problem23.zig](../../../zig/p/problem23.zig) |
