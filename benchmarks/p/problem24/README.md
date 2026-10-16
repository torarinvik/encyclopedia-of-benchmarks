# Problem 24: Lexicographic permutations

This package reproduces the fixed result from TheAlgorithms/Python at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, file `project_euler/problem_024/sol1.py`. The pinned `solution()` enumerates permutations of the sorted digits `0123456789` and returns the one-based millionth entry, `2783915460`.

The ports compute that same entry with factorial-number-system unranking instead of materializing all 3,628,800 permutations. The source takes no arguments; the scalar ABI accepts a zero-valued placeholder only so the shared runner can call the fixed computation. The result has no leading zero, so the ten-digit string is represented exactly as an `i64`.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem24.c](../../../c/p/problem24.c) |
| C3 | [c3/p/problem24.c3](../../../c3/p/problem24.c3) |
| C++ | [cpp/p/problem24.cpp](../../../cpp/p/problem24.cpp) |
| Elisa | [elisa/p/problem24.elisa](../../../elisa/p/problem24.elisa) |
| Nim | [nim/p/problem24.nim](../../../nim/p/problem24.nim) |
| Odin | [odin/p/problem24.odin](../../../odin/p/problem24.odin) |
| Rust | [rust/p/problem24.rs](../../../rust/p/problem24.rs) |
| V | [v/p/problem24.v](../../../v/p/problem24.v) |
| Zig | [zig/p/problem24.zig](../../../zig/p/problem24.zig) |
