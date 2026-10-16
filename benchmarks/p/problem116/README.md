# Project Euler Problem 116: Red, green, or blue tiles

## Contract

For each row length from 0 through `length`, the pinned Python source visits tile lengths 2, 3, and 4 separately. At each possible start position it adds the number of same-color arrangements in the remaining suffix plus one for the arrangement beginning with that colored tile. It sums the three color counts for the requested row, so colors are never mixed and at least one colored tile is present.

The benchmark supports lengths 0 through 91 and returns -1 outside that domain. Negative lengths make the source build an empty table and then index it, so they are invalid. The upper bound 91 is the largest row length whose total fits signed 64 bit; length 92 exceeds that range. The source default is 50 and returns 20,492,570,929. Its example returns 12 for length 5.

The ports preserve the source's row, tile-length, and tile-start loop bounds and recurrence using an integer DP table.

## Workload

The [workload JSON](workload.json) covers small row boundaries, the source example and default, the maximum signed 64 bit result, and out-of-domain values.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_116/sol1.py) counts each block length independently and sums the single-color arrangements.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem116.c](../../../c/p/problem116.c) |
| C3 | [c3/p/problem116.c3](../../../c3/p/problem116.c3) |
| C++ | [cpp/p/problem116.cpp](../../../cpp/p/problem116.cpp) |
| Elisa | [elisa/p/problem116.elisa](../../../elisa/p/problem116.elisa) |
| Nim | [nim/p/problem116.nim](../../../nim/p/problem116.nim) |
| Odin | [odin/p/problem116.odin](../../../odin/p/problem116.odin) |
| Rust | [rust/p/problem116.rs](../../../rust/p/problem116.rs) |
| V | [v/p/problem116.v](../../../v/p/problem116.v) |
| Zig | [zig/p/problem116.zig](../../../zig/p/problem116.zig) |
