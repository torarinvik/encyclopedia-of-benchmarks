# Project Euler Problem 28

## Contract

Return the sum of both diagonals in the clockwise square spiral of side length `size`, using the pinned Python source's corner-layer recurrence, for `size` in `0..=100000`. Inputs outside that range return `-1`.

The source starts with `total = 1`, then processes `i` from 1 through `ceil(size / 2) - 1`. For each layer it adds the four corners as `4 * (2*i + 1)^2 - 6 * (2*i)`. This source behavior also defines even side lengths; for example, it returns 25 for size 4. Integer arithmetic matches the source for the bounded domain.

Each language exports a C ABI function:

```c
int64_t problem28(int64_t size);
```

## Workload

[`workload.json`](workload.json) covers empty and small spirals, the source's examples, the canonical size 1001, the maximum supported input, and invalid inputs. The runner checks results using the corner recurrence. The verifier uses its closed-form sum as an independent oracle.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_028/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem28.c](../../../c/p/problem28.c) |
| C3 | [c3/p/problem28.c3](../../../c3/p/problem28.c3) |
| C++ | [cpp/p/problem28.cpp](../../../cpp/p/problem28.cpp) |
| Elisa | [elisa/p/problem28.elisa](../../../elisa/p/problem28.elisa) |
| Nim | [nim/p/problem28.nim](../../../nim/p/problem28.nim) |
| Odin | [odin/p/problem28.odin](../../../odin/p/problem28.odin) |
| Rust | [rust/p/problem28.rs](../../../rust/p/problem28.rs) |
| V | [v/p/problem28.v](../../../v/p/problem28.v) |
| Zig | [zig/p/problem28.zig](../../../zig/p/problem28.zig) |
