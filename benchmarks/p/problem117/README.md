# Project Euler Problem 117

## Contract

The pinned Python source counts tilings of a row using grey unit tiles and colored oblong tiles of lengths two, three, and four. Any tile types may be adjacent, and the source counts each ordered tiling once. It initializes one all-grey arrangement and adds the source's placement recurrence for each colored tile length. The benchmark accepts row lengths 0 through 67; negative lengths and lengths above 67 return `-1` because the exact count exceeds the signed 64-bit result range after 67.

The ports use the equivalent recurrence `ways[n] = ways[n-1] + ways[n-2] + ways[n-3] + ways[n-4]`, with `ways[0] = 1`. The source example for length five returns 15; the canonical length fifty returns `100808458960497`.

Each language exports `int64_t problem117(int64_t length)`.

## Workload

[`workload.json`](workload.json) covers lengths zero through five, the documented example, canonical length 50, the largest signed-64-bit-safe length, and invalid bounds.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_117/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem117.c](../../../c/p/problem117.c) |
| C3 | [c3/p/problem117.c3](../../../c3/p/problem117.c3) |
| C++ | [cpp/p/problem117.cpp](../../../cpp/p/problem117.cpp) |
| Elisa | [elisa/p/problem117.elisa](../../../elisa/p/problem117.elisa) |
| Nim | [nim/p/problem117.nim](../../../nim/p/problem117.nim) |
| Odin | [odin/p/problem117.odin](../../../odin/p/problem117.odin) |
| Rust | [rust/p/problem117.rs](../../../rust/p/problem117.rs) |
| V | [v/p/problem117.v](../../../v/p/problem117.v) |
| Zig | [zig/p/problem117.zig](../../../zig/p/problem117.zig) |
