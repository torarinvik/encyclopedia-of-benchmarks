# Project Euler Problem 97: Large non-Mersenne prime

## Contract

The pinned Python function takes a digit count `n`, computes the executable expression `28433 × 2^7830457 + 1` modulo `10^n`, and returns the remainder as decimal text without zero padding. The benchmark exposes that remainder as a signed 64 bit integer, which has the same numeric value as the source's returned text. In particular, `n=0` yields `"0"` / integer 0.

The source prose describes a different placement of `+1`; this package follows the executable function body, which multiplies the modular power by 28,433 and then adds 1. The benchmark supports `n` from 0 through 18 so every suffix fits the scalar integer ABI; negative values and values above 18 return -1. The source examples include `n=1` → 7, `n=8` → 39,992,577, and the default `n=10` → 8,739,992,577.

The ports use binary modular exponentiation. Their modular multiplication uses repeated doubling, avoiding intermediate overflow while preserving the source's exact modulo result.

## Workload

The [workload JSON](workload.json) covers zero digits, the source examples and default, an 18-digit boundary result, and invalid values outside the benchmark domain.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_097/sol1.py) computes the modular power and returns the unpadded decimal suffix.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem97.c](../../../c/p/problem97.c) |
| C3 | [c3/p/problem97.c3](../../../c3/p/problem97.c3) |
| C++ | [cpp/p/problem97.cpp](../../../cpp/p/problem97.cpp) |
| Elisa | [elisa/p/problem97.elisa](../../../elisa/p/problem97.elisa) |
| Nim | [nim/p/problem97.nim](../../../nim/p/problem97.nim) |
| Odin | [odin/p/problem97.odin](../../../odin/p/problem97.odin) |
| Rust | [rust/p/problem97.rs](../../../rust/p/problem97.rs) |
| V | [v/p/problem97.v](../../../v/p/problem97.v) |
| Zig | [zig/p/problem97.zig](../../../zig/p/problem97.zig) |
