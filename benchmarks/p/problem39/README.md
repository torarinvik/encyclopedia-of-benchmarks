# Project Euler Problem 39: Integer right triangles

## Contract

For an inclusive perimeter limit `n` in `12..=1000`, return the perimeter with the largest number of integer right-triangle solutions. Invalid limits return `-1`. The lower bound excludes inputs for which the pinned Python source would fail on an empty `Counter`.

The source visits `base` from 1 through `n`, then `perpendicular` from `base` through `n`. It counts a triple when `sqrt(base² + perpendicular²)` is exactly integral and the perimeter does not exceed `n`. Equal maximum counts are resolved by `Counter.most_common(1)`, which keeps the first perimeter inserted by those nested loops. For example, at `n = 24`, perimeters 12 and 24 tie with one triple each, and the source returns 12. The ports use an integer square root; throughout this bounded input, this is equivalent to the source's float-square-root equality check.

Documented results are `solution(100) = 90`, `solution(200) = 180`, and `solution(1000) = 840`.

## Workload

[`workload.json`](workload.json) includes the 12 and 15 perimeter boundaries, the tie at 24, the source examples at 40, 50, 100, and 200, the canonical 1000 result, and invalid bounds. The 100 case also checks tie selection among the maximum-count perimeters.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_039/sol1.py) counts triples in nested side loops and returns the most common perimeter.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem39.c](../../../c/p/problem39.c) |
| C3 | [c3/p/problem39.c3](../../../c3/p/problem39.c3) |
| C++ | [cpp/p/problem39.cpp](../../../cpp/p/problem39.cpp) |
| Elisa | [elisa/p/problem39.elisa](../../../elisa/p/problem39.elisa) |
| Nim | [nim/p/problem39.nim](../../../nim/p/problem39.nim) |
| Odin | [odin/p/problem39.odin](../../../odin/p/problem39.odin) |
| Rust | [rust/p/problem39.rs](../../../rust/p/problem39.rs) |
| V | [v/p/problem39.v](../../../v/p/problem39.v) |
| Zig | [zig/p/problem39.zig](../../../zig/p/problem39.zig) |
