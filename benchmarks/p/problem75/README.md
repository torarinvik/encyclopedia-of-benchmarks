# Project Euler Problem 75: Singular integer right triangles

## Contract

`problem75(limit)` counts perimeter values `L <= limit` that can form exactly one integer-sided right triangle. The package bounds positive work to 1,500,000, matching the pinned source's canonical call; a larger bound returns `-1`. Negative bounds preserve the source's empty search and return 0.

The ports enumerate primitive triples with Euclid's formula. They visit `m` from 2 while `2*m*(m+1) <= limit`, then `n` from `(m % 2)+1` to `m` exclusive in steps of 2, retaining coprime pairs. Each primitive perimeter `2*m*(m+n)` increments all of its multiples through the inclusive limit. Frequencies saturate at 2 because only the exactly-one case matters.

The source examples return 6 for 50, 112 for 1,000, and 5,502 for 50,000. The canonical 1,500,000 limit returns 161,667. The workload records one call per sample because it allocates and scans a frequency table up to the requested limit.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_075/sol1.py) uses a default limit of 1,500,000, enumerates Euclid parameter pairs with the parity step and gcd check above, counts every primitive perimeter multiple up to and including the limit, then counts dictionary frequencies equal to one. The ports preserve those bounds and counting semantics.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem75.c](../../../c/p/problem75.c) |
| C3 | [c3/p/problem75.c3](../../../c3/p/problem75.c3) |
| C++ | [cpp/p/problem75.cpp](../../../cpp/p/problem75.cpp) |
| Elisa | [elisa/p/problem75.elisa](../../../elisa/p/problem75.elisa) |
| Nim | [nim/p/problem75.nim](../../../nim/p/problem75.nim) |
| Odin | [odin/p/problem75.odin](../../../odin/p/problem75.odin) |
| Rust | [rust/p/problem75.rs](../../../rust/p/problem75.rs) |
| V | [v/p/problem75.v](../../../v/p/problem75.v) |
| Zig | [zig/p/problem75.zig](../../../zig/p/problem75.zig) |
