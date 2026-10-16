# Project Euler Problem 91: Right triangles with integer coordinates

## Contract

The pinned Python source counts unordered pairs of distinct points P and Q from the integer grid `[0, limit] × [0, limit]`. It excludes the origin as either point, computes the squared lengths OP, OQ, and PQ, and counts a pair when any one of the three Pythagorean equalities holds. The point coordinates include both grid boundaries, and each triangle is counted once because the source uses `itertools.combinations`.

The scalar input `limit` is supported from 0 through 50; values outside that benchmark domain return -1. The source default is 50 and returns 14,234. Its examples return 14 for limit 2 and 448 for limit 10. The ports preserve the source's lexicographic point-pair order with nested loops and use integer arithmetic for the squared distances.

## Workload

The [workload JSON](workload.json) covers the empty grid, a one-unit grid, both source examples, the source default, and out-of-domain values.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_091/sol1.py) enumerates all unordered grid-point pairs and tests their squared side lengths.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem91.c](../../../c/p/problem91.c) |
| C3 | [c3/p/problem91.c3](../../../c3/p/problem91.c3) |
| C++ | [cpp/p/problem91.cpp](../../../cpp/p/problem91.cpp) |
| Elisa | [elisa/p/problem91.elisa](../../../elisa/p/problem91.elisa) |
| Nim | [nim/p/problem91.nim](../../../nim/p/problem91.nim) |
| Odin | [odin/p/problem91.odin](../../../odin/p/problem91.odin) |
| Rust | [rust/p/problem91.rs](../../../rust/p/problem91.rs) |
| V | [v/p/problem91.v](../../../v/p/problem91.v) |
| Zig | [zig/p/problem91.zig](../../../zig/p/problem91.zig) |
