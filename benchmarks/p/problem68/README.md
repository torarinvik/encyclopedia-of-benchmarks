# Project Euler Problem 68: Magic gon rings

## Contract

`problem68(gon_side)` returns the first magic ring found for `gon_side` 3, 4, or 5, represented by concatenating each clockwise line beginning with the line whose external node is the smallest. Other side counts return `-1` as the portable sentinel for the source's range error.

The ports preserve the pinned source's ordered permutation traversal: values `gon_side+1` down to 1 followed by `gon_side+2` up to `2*gon_side`. They generate the same line triples from each permutation, require all line sums to match and the first external node to be the minimum, then return immediately on the first match. The number is accumulated digit by digit, including the two decimal digits of 10.

The source examples are 432621513 for 3-gon, 426561813732 for 4-gon, and 6531031914842725 for 5-gon. The 5-gon search may visit up to 10! ordered permutations, so the workload records one invocation per sample.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_068/sol1.py) constructs its ordered input list as descending `gon_side+1 .. 1` values followed by ascending `gon_side+2 .. 2*gon_side` values, then iterates `itertools.permutations` in that order. It returns the first generated ring passing equal-line-sum and minimum-external checks. The package preserves that traversal and first-match tie behavior.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem68.c](../../../c/p/problem68.c) |
| C3 | [c3/p/problem68.c3](../../../c3/p/problem68.c3) |
| C++ | [cpp/p/problem68.cpp](../../../cpp/p/problem68.cpp) |
| Elisa | [elisa/p/problem68.elisa](../../../elisa/p/problem68.elisa) |
| Nim | [nim/p/problem68.nim](../../../nim/p/problem68.nim) |
| Odin | [odin/p/problem68.odin](../../../odin/p/problem68.odin) |
| Rust | [rust/p/problem68.rs](../../../rust/p/problem68.rs) |
| V | [v/p/problem68.v](../../../v/p/problem68.v) |
| Zig | [zig/p/problem68.zig](../../../zig/p/problem68.zig) |
