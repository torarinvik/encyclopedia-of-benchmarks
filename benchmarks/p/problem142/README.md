# Project Euler Problem 142: Perfect square collection

## Contract

The pinned source special-cases `number_of_terms=1` to return 1 and `number_of_terms=2` to return 9. For 3, it searches square indices `a,b` from 1 through 2,500, then `c` from `max(a,b)+1` through 2,500. It requires `a²+b²`, `c²-b²`, and `a²+c²` to be in the source's square set (0² through 2,500²). It derives doubled values `x2=a²+b²+c²`, `y2=a²-b²+c²`, and `z2=c²-a²-b²`, then accepts only positive z and even x2, y2, and z2. It returns the minimum `(x2+y2+z2)/2`, which is 1,006,193.

The search preserves the source's early break when `(a²-b²+3c²)//2` exceeds the best sum. The benchmark supports input values 1 through 3; other values return -1. For input 3, the fixed source search bound is 2,500. Square membership is checked by binary search in the same bounded square range.

## Workload

The [workload JSON](workload.json) covers the two special cases, the source's default three-term search, and values outside the supported input domain.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_142/sol1.py) searches the bounded square-index combinations and keeps the minimum sum.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem142.c](../../../c/p/problem142.c) |
| C3 | [c3/p/problem142.c3](../../../c3/p/problem142.c3) |
| C++ | [cpp/p/problem142.cpp](../../../cpp/p/problem142.cpp) |
| Elisa | [elisa/p/problem142.elisa](../../../elisa/p/problem142.elisa) |
| Nim | [nim/p/problem142.nim](../../../nim/p/problem142.nim) |
| Odin | [odin/p/problem142.odin](../../../odin/p/problem142.odin) |
| Rust | [rust/p/problem142.rs](../../../rust/p/problem142.rs) |
| V | [v/p/problem142.v](../../../v/p/problem142.v) |
| Zig | [zig/p/problem142.zig](../../../zig/p/problem142.zig) |
