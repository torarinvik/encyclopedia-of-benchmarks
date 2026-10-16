# Project Euler Problem 71: Ordered fractions

## Contract

The pinned Python source scans every denominator from 1 through the requested limit, inclusive. For each denominator it takes floor(denominator × target numerator / target denominator), subtracts one when the denominator is a multiple of the target denominator to exclude the target fraction, and updates the best candidate only when a strict cross multiplication improves the fraction.

The array-scalar input is [target numerator, target denominator, limit]. It accepts a reduced proper target fraction (0 < numerator < denominator <= 1,000,000, with gcd 1) and limits from 1 through 1,000,000. Other shapes or values return -1. The reduced-fraction constraint preserves the source's divisibility check for excluding equality.

The default call returns 428,570 for 3/7 with limit 1,000,000. The source examples include 3/7 with limit 8 returning 2 and 6/7 with limit 60 returning 47.

## Workload

The [workload JSON](workload.json) covers the default, both documented examples, another proper fraction, small limits, and invalid inputs.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_071/sol1.py) performs the inclusive denominator scan and strict cross-multiplication comparison.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem71.c](../../../c/p/problem71.c) |
| C3 | [c3/p/problem71.c3](../../../c3/p/problem71.c3) |
| C++ | [cpp/p/problem71.cpp](../../../cpp/p/problem71.cpp) |
| Elisa | [elisa/p/problem71.elisa](../../../elisa/p/problem71.elisa) |
| Nim | [nim/p/problem71.nim](../../../nim/p/problem71.nim) |
| Odin | [odin/p/problem71.odin](../../../odin/p/problem71.odin) |
| Rust | [rust/p/problem71.rs](../../../rust/p/problem71.rs) |
| V | [v/p/problem71.v](../../../v/p/problem71.v) |
| Zig | [zig/p/problem71.zig](../../../zig/p/problem71.zig) |
