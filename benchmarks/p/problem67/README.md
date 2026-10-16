# Project Euler Problem 67

## Contract

The pinned Python source reads the adjacent `triangle.txt`, parses 100 rows, and folds each row into the maximum total from the top to an adjacent entry on the bottom row. The benchmark uses an array adapter so every language receives the same bundled dataset without runtime file dependencies. The packed input is `[row_count, flattened triangle rows]`; it accepts 1–100 rows, values from 0 through 1,000,000, and returns `-1` for malformed inputs. The pinned dataset returns `7273`.

The workload embeds the exact 100-row triangle from the pinned source revision. It also includes the source statement example and invalid shape/value cases.

Each language exports an array-scalar function equivalent to:

```c
int64_t problem67(const int64_t *input, size_t length);
```

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_067/sol1.py)
- Data [`triangle.txt`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_067/triangle.txt)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem67.c](../../../c/p/problem67.c) |
| C3 | [c3/p/problem67.c3](../../../c3/p/problem67.c3) |
| C++ | [cpp/p/problem67.cpp](../../../cpp/p/problem67.cpp) |
| Elisa | [elisa/p/problem67.elisa](../../../elisa/p/problem67.elisa) |
| Nim | [nim/p/problem67.nim](../../../nim/p/problem67.nim) |
| Odin | [odin/p/problem67.odin](../../../odin/p/problem67.odin) |
| Rust | [rust/p/problem67.rs](../../../rust/p/problem67.rs) |
| V | [v/p/problem67.v](../../../v/p/problem67.v) |
| Zig | [zig/p/problem67.zig](../../../zig/p/problem67.zig) |
