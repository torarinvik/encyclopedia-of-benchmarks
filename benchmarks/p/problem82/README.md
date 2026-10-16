# Project Euler Problem 82

## Contract

Given a nonempty rectangular matrix of nonnegative cell costs, return the minimum path sum from any cell in the left column to any cell in the right column. A move may go one cell up, down, or right. The packed input is `[rows, columns, row-major cell costs...]`; each dimension is in `1..=80` and each cost is in `0..=9999`. Invalid input returns `-1`.

The ports use the pinned source's column-by-column dynamic program. For each new column they first extend the path totals from the previous column, then relax downward and upward within that column. They keep one total per row, for O(rows × columns) time and O(rows) auxiliary space.

The statement's 5×5 example returns **994**. The pinned 80×80 matrix returns **260324**. The official matrix is included row-major in the canonical workload case, so benchmark inputs are portable and do not depend on a runtime file lookup.

## Workload

[`workload.json`](workload.json) covers the statement and canonical matrices, rectangular and degenerate shapes, vertical movement in both directions, and malformed dimensions and costs.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_082/sol1.py)
- Official matrix resource: [p082_matrix.txt](https://projecteuler.net/project/resources/p082_matrix.txt)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem82.c](../../../c/p/problem82.c) |
| C3 | [c3/p/problem82.c3](../../../c3/p/problem82.c3) |
| C++ | [cpp/p/problem82.cpp](../../../cpp/p/problem82.cpp) |
| Elisa | [elisa/p/problem82.elisa](../../../elisa/p/problem82.elisa) |
| Nim | [nim/p/problem82.nim](../../../nim/p/problem82.nim) |
| Odin | [odin/p/problem82.odin](../../../odin/p/problem82.odin) |
| Rust | [rust/p/problem82.rs](../../../rust/p/problem82.rs) |
| V | [v/p/problem82.v](../../../v/p/problem82.v) |
| Zig | [zig/p/problem82.zig](../../../zig/p/problem82.zig) |
