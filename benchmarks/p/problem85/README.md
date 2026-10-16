# Project Euler Problem 85: Counting rectangles

## Contract

For a grid with sides a and b, the pinned Python source computes its rectangle count as T(a) × T(b), where T(n)=n(n+1)/2. It searches a from 1 up to, but excluding, ceil(sqrt(2 × target) × 1.1). For each a it computes the quadratic estimate for b, checks floor(b) first and ceil(b) second, and updates only when the absolute error is strictly smaller. That update order preserves the first candidate on ties. The result is the selected grid area a × b.

The scalar input target is bounded to 0 through 2,000,000,000; values outside that domain return -1. The pinned no-argument call uses target 2,000,000 and returns 2,772. The source examples include targets 20, 2,000, and 2,000,000,000, returning 6, 72, and 86,595.

The ports compute the same triangular products directly instead of materializing the source's triangle-number list. They retain the source's floating-point bounds and b estimates, strict comparisons, candidate order, and exclusive a bound.

## Workload

The [workload JSON](workload.json) covers zero and small targets, the source examples and default, a target that exercises strict tie handling, and invalid values outside the supported domain.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_085/sol1.py) searches products of triangular numbers and returns the area of the closest grid.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem85.c](../../../c/p/problem85.c) |
| C3 | [c3/p/problem85.c3](../../../c3/p/problem85.c3) |
| C++ | [cpp/p/problem85.cpp](../../../cpp/p/problem85.cpp) |
| Elisa | [elisa/p/problem85.elisa](../../../elisa/p/problem85.elisa) |
| Nim | [nim/p/problem85.nim](../../../nim/p/problem85.nim) |
| Odin | [odin/p/problem85.odin](../../../odin/p/problem85.odin) |
| Rust | [rust/p/problem85.rs](../../../rust/p/problem85.rs) |
| V | [v/p/problem85.v](../../../v/p/problem85.v) |
| Zig | [zig/p/problem85.zig](../../../zig/p/problem85.zig) |
