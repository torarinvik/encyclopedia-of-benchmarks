# Project Euler Problem 37: Truncatable primes

## Contract

Find the eleven primes that remain prime after successively removing digits from either the left or the right, excluding single-digit primes, and return their sum. The source set is fixed; the result is 748,317.

Each port scans odd candidates from 13 through 1,000,000, checks primality, then checks every nonempty proper prefix and suffix. The search ceiling includes the largest member of the source's eleven-value set, 739,397. Prime checks use trial division by 6k±1 candidates through the square root. The scalar ABI accepts a zero placeholder because the source operation has no input; nonzero values return `-1`.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_037/sol1.py) searches from 13 for eleven values, checks all left and right truncations, and sums the resulting set. Its documented eleven values are `23, 37, 53, 73, 313, 317, 373, 797, 3137, 3797, 739397`, whose sum is 748,317. Its three-digit prefix/suffix check is only a rejection shortcut; it does not change the accepted set.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem37.c](../../../c/p/problem37.c) |
| C3 | [c3/p/problem37.c3](../../../c3/p/problem37.c3) |
| C++ | [cpp/p/problem37.cpp](../../../cpp/p/problem37.cpp) |
| Elisa | [elisa/p/problem37.elisa](../../../elisa/p/problem37.elisa) |
| Nim | [nim/p/problem37.nim](../../../nim/p/problem37.nim) |
| Odin | [odin/p/problem37.odin](../../../odin/p/problem37.odin) |
| Rust | [rust/p/problem37.rs](../../../rust/p/problem37.rs) |
| V | [v/p/problem37.v](../../../v/p/problem37.v) |
| Zig | [zig/p/problem37.zig](../../../zig/p/problem37.zig) |
