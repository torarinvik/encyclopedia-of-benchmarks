# Project Euler Problem 86: Cuboid route count

## Contract

`problem86(limit)` returns the least maximum side length `M` for which the cumulative count of integer shortest surface paths over cuboids `1 <= a <= b <= c <= M` is strictly greater than `limit`. The workload bounds `limit` to 0..1,000,000; larger limits return `-1`. Negative limits preserve the source's initially-false loop and return 0.

For each increasing `M`, the ports inspect `d = a+b` from 2 through `2*M` inclusive. A cuboid contributes when `d²+M²` is a perfect square. For each such `d`, the number of valid ordered pairs is `min(M, d//2) + 1 - max(1, d-M)`. The code finishes the full current `M` layer before checking whether the cumulative count is now greater than the threshold, matching the source's outer stopping condition. Integer square checks use an exact integer square root.

The source examples are 24 for threshold 100, 72 for 1,000, 100 for 2,000, and 288 for 20,000. For the canonical threshold 1,000,000, the result is 1,818.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_086/sol1.py) begins at `M=0`, loops while the count is `<= limit`, increments `M`, and checks every `d` in `range(2, 2*M+1)`. It uses `sqrt(d*d + M*M).is_integer()` and adds the pair-count formula above. The package preserves the inclusive `d=2*M` iteration and whole-layer stopping order; the exact integer square predicate is equivalent over the bounded workload.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem86.c](../../../c/p/problem86.c) |
| C3 | [c3/p/problem86.c3](../../../c3/p/problem86.c3) |
| C++ | [cpp/p/problem86.cpp](../../../cpp/p/problem86.cpp) |
| Elisa | [elisa/p/problem86.elisa](../../../elisa/p/problem86.elisa) |
| Nim | [nim/p/problem86.nim](../../../nim/p/problem86.nim) |
| Odin | [odin/p/problem86.odin](../../../odin/p/problem86.odin) |
| Rust | [rust/p/problem86.rs](../../../rust/p/problem86.rs) |
| V | [v/p/problem86.v](../../../v/p/problem86.v) |
| Zig | [zig/p/problem86.zig](../../../zig/p/problem86.zig) |
