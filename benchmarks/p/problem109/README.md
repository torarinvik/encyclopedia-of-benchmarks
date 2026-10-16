# Project Euler Problem 109

## Contract

The pinned Python source counts dart checkouts with total score strictly less than `limit`. It builds the 63 possible first/second dart outcomes from 21 singles, 21 doubles, 20 triples, and a miss; the first two darts are selected with combinations-with-replacement, so their order does not matter. The final dart is selected from the 21 doubles, and its position is significant. Repeated numeric scores from different dart regions remain distinct source entries. There is no additional input bound; the maximum score is 170, so any limit above 170 returns 42,336.

Each language exports `int64_t problem109(int64_t limit)`.

## Workload

[`workload.json`](workload.json) covers the exclusive score threshold, the source examples, canonical limit 100 (38,182), maximum checkout score, and signed 64-bit extremes.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_109/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem109.c](../../../c/p/problem109.c) |
| C3 | [c3/p/problem109.c3](../../../c3/p/problem109.c3) |
| C++ | [cpp/p/problem109.cpp](../../../cpp/p/problem109.cpp) |
| Elisa | [elisa/p/problem109.elisa](../../../elisa/p/problem109.elisa) |
| Nim | [nim/p/problem109.nim](../../../nim/p/problem109.nim) |
| Odin | [odin/p/problem109.odin](../../../odin/p/problem109.odin) |
| Rust | [rust/p/problem109.rs](../../../rust/p/problem109.rs) |
| V | [v/p/problem109.v](../../../v/p/problem109.v) |
| Zig | [zig/p/problem109.zig](../../../zig/p/problem109.zig) |
