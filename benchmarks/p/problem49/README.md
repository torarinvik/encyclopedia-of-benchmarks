# Project Euler Problem 49: Prime permutations

## Contract

The pinned Python `solution()` takes no arguments and returns the largest 12-digit concatenation of a selected arithmetic progression of 4-digit odd primes that are permutations of one another. The scalar ABI uses zero as an ignored placeholder; nonzero values return `-1`. The fixed result is `296,962,999,629`.

The source creates primes from the odd values in `[1001, 10000)`. For each prime it sorts the prime-valued permutations of its digits, then scans triples in increasing list-index order and keeps the first 3-term arithmetic progression for that digit family. It returns the maximum concatenation across the families. The ports group the prime list by sorted digit signature, which is equivalent to the source permutation lists; they keep the same ascending triple scan and first progression per family. Repeated permutations from repeated digits do not alter the first distinct triple.

## Workload

[`workload.json`](workload.json) covers the fixed source computation and both positive and negative invalid placeholders.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_049/sol1.py) generates four-digit primes, groups prime permutations, finds the first arithmetic progression in each group, and returns the largest concatenated result.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem49.c](../../../c/p/problem49.c) |
| C3 | [c3/p/problem49.c3](../../../c3/p/problem49.c3) |
| C++ | [cpp/p/problem49.cpp](../../../cpp/p/problem49.cpp) |
| Elisa | [elisa/p/problem49.elisa](../../../elisa/p/problem49.elisa) |
| Nim | [nim/p/problem49.nim](../../../nim/p/problem49.nim) |
| Odin | [odin/p/problem49.odin](../../../odin/p/problem49.odin) |
| Rust | [rust/p/problem49.rs](../../../rust/p/problem49.rs) |
| V | [v/p/problem49.v](../../../v/p/problem49.v) |
| Zig | [zig/p/problem49.zig](../../../zig/p/problem49.zig) |
