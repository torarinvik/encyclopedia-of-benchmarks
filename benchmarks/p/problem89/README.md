# Project Euler Problem 89: Roman numeral savings

## Contract

`problem89(0)` parses the 1,000 Roman numerals from [`roman.txt`](roman.txt), converts each value to standard minimal form, and returns the total character savings: 743. A nonzero placeholder returns `-1`; this gives the file-based source a portable scalar ABI without runtime file access.

The nine ports embed the pinned records in a compact representation: each record stores its length and 3-bit symbol codes. Every call decodes each record using the source's adjacent-symbol subtractive rule, then computes the minimal-form length by greedily applying the standard tokens `M, CM, D, CD, C, XC, L, XL, X, IX, V, IV, I`. The packed data preserves each line's exact length and symbol order.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_089/sol1.py) reads the adjacent `p089_roman.txt`, strips each line, parses by subtracting a symbol when it is less than the next symbol, and generates minimal form with thousands plus the 900/400, 90/40, and 9/4 subtractive forms. The source states that no numeral has more than four consecutive identical units. This package uses the exact pinned 1,000-line data file and preserves the parser and minimal-form counting behavior.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem89.c](../../../c/p/problem89.c) |
| C3 | [c3/p/problem89.c3](../../../c3/p/problem89.c3) |
| C++ | [cpp/p/problem89.cpp](../../../cpp/p/problem89.cpp) |
| Elisa | [elisa/p/problem89.elisa](../../../elisa/p/problem89.elisa) |
| Nim | [nim/p/problem89.nim](../../../nim/p/problem89.nim) |
| Odin | [odin/p/problem89.odin](../../../odin/p/problem89.odin) |
| Rust | [rust/p/problem89.rs](../../../rust/p/problem89.rs) |
| V | [v/p/problem89.v](../../../v/p/problem89.v) |
| Zig | [zig/p/problem89.zig](../../../zig/p/problem89.zig) |
