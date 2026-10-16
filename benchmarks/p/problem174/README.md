# Project Euler Problem 174: counting square laminae

## Contract

`problem174(t_limit, n_limit)` returns how many positive tile counts `t <= t_limit` can be made by between one and `n_limit` distinct square laminae. The pinned routine counts centered square holes, so the outer and hole widths must have the same parity, and the hole width must be at least 1. The package supports `t_limit <= 1,000,000`; values above that bound return `-1`. Negative tile limits and nonpositive `n_limit` return 0, matching the pinned routine's empty count predicate/range.

The ports follow the pinned outer-width scan. For each outer square they choose the smallest inner width whose square difference is within the tile bound, then adjust it to match parity and add every valid inner width in steps of two. An exact integer ceiling-square-root helper preserves the source's lower-bound calculation. Per-tile representation counts fit in one byte on this bounded domain: each lamina corresponds to a distinct factor pair of its tile count, whose maximum divisor count below one million is below 256.

The pinned examples return 222 for `(1000, 5)`, 249 for `(1000, 10)`, and 2,383 for `(10000, 10)`. The canonical default `(1000000, 10)` returns **209,566**.

## Workload

[`workload.json`](workload.json) covers zero and small thresholds, the pinned examples, the canonical limit, nonpositive count limits, and inputs above the supported tile bound.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_174/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem174.c](../../../c/p/problem174.c) |
| C3 | [c3/p/problem174.c3](../../../c3/p/problem174.c3) |
| C++ | [cpp/p/problem174.cpp](../../../cpp/p/problem174.cpp) |
| Elisa | [elisa/p/problem174.elisa](../../../elisa/p/problem174.elisa) |
| Nim | [nim/p/problem174.nim](../../../nim/p/problem174.nim) |
| Odin | [odin/p/problem174.odin](../../../odin/p/problem174.odin) |
| Rust | [rust/p/problem174.rs](../../../rust/p/problem174.rs) |
| V | [v/p/problem174.v](../../../v/p/problem174.v) |
| Zig | [zig/p/problem174.zig](../../../zig/p/problem174.zig) |
