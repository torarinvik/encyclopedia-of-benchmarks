# Project Euler Problem 102: Triangles containing the origin

## Contract

The pinned Python source reads 1,000 rows from `p102_triangles.txt`. Each row has six coordinates `(x1,y1,x2,y2,x3,y3)` for a triangle, with each coordinate between -1,000 and 1,000. The workload embeds those 6,000 integers in source-file order and passes them as a packed signed 64 bit integer array. The ports also accept 1 to 1,000 triangles in that same six-value layout.

A triangle counts only when the origin is in its strict interior. The source computes two barycentric weights from cross products and requires both weights to be positive and their sum to be less than one. The ports use equivalent exact integer inequalities after normalizing triangle orientation, so points on an edge or vertex do not count. A zero-area triangle causes division by zero in the source; this contract maps such input to -1, as it does for malformed arrays or coordinates outside the source range.

The pinned 1,000-row dataset yields 228. The source's first example contains the origin and its second example does not, so the two-row case returns 1.

## Workload

The [workload JSON](workload.json) embeds the pinned data as the primary case and includes both source examples, a boundary case, and invalid input shapes.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_102/sol1.py) counts triangles whose strict interior contains the origin.
- Dataset [p102_triangles.txt](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_102/p102_triangles.txt) contains the 1,000 coordinate rows embedded in the workload.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem102.c](../../../c/p/problem102.c) |
| C3 | [c3/p/problem102.c3](../../../c3/p/problem102.c3) |
| C++ | [cpp/p/problem102.cpp](../../../cpp/p/problem102.cpp) |
| Elisa | [elisa/p/problem102.elisa](../../../elisa/p/problem102.elisa) |
| Nim | [nim/p/problem102.nim](../../../nim/p/problem102.nim) |
| Odin | [odin/p/problem102.odin](../../../odin/p/problem102.odin) |
| Rust | [rust/p/problem102.rs](../../../rust/p/problem102.rs) |
| V | [v/p/problem102.v](../../../v/p/problem102.v) |
| Zig | [zig/p/problem102.zig](../../../zig/p/problem102.zig) |
