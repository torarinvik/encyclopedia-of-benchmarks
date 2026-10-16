# Project Euler Problem 16

## Contract

Return the sum of the decimal digits of `2^exponent`, for `exponent` in `0..=1000`. Values outside that range return `-1`.

The ports store the value as little-endian decimal digits and multiply by two once per exponent step, taking O(exponent²) time and O(exponent) space. The pinned Go source uses `math/big` exponentiation, converts the result to decimal text, and sums those digits. The bounded ports reproduce that result without a big-integer dependency.

## Workload

[`workload.json`](workload.json) covers exponent zero, small powers, the 2^15 example, the canonical exponent 1000, and invalid bounds.

## TheAlgorithms reference

- Go [`Problem16`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_16/problem16.go) computes `2^exponent` with `math/big` and sums the digits of its decimal representation.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem16.c](../../../c/p/problem16.c) |
| C3 | [c3/p/problem16.c3](../../../c3/p/problem16.c3) |
| C++ | [cpp/p/problem16.cpp](../../../cpp/p/problem16.cpp) |
| Elisa | [elisa/p/problem16.elisa](../../../elisa/p/problem16.elisa) |
| Nim | [nim/p/problem16.nim](../../../nim/p/problem16.nim) |
| Odin | [odin/p/problem16.odin](../../../odin/p/problem16.odin) |
| Rust | [rust/p/problem16.rs](../../../rust/p/problem16.rs) |
| V | [v/p/problem16.v](../../../v/p/problem16.v) |
| Zig | [zig/p/problem16.zig](../../../zig/p/problem16.zig) |
