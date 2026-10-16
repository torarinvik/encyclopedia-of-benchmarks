# Project Euler Problem 104

## Contract

The fixed computation returns the first Fibonacci index whose first and last nine decimal digits are each 1-to-9 pandigital. The scalar ABI accepts placeholder zero and returns `-1` for any other value. The pinned search examines indices 3 through 1,000,002 in ascending order; the result is **329468**.

The ports scan indices in ascending order with an exact base-1,000,000,000 Fibonacci integer stored in two rotating limb buffers. The low limb supplies the exact trailing nine digits; the top one or two limbs supply the exact leading nine digits. They return at the first index passing both pandigital filters, without floating-point digit estimates.

## Workload

[`workload.json`](workload.json) covers the fixed source calculation and nonzero placeholders.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_104/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem104.c](../../../c/p/problem104.c) |
| C3 | [c3/p/problem104.c3](../../../c3/p/problem104.c3) |
| C++ | [cpp/p/problem104.cpp](../../../cpp/p/problem104.cpp) |
| Elisa | [elisa/p/problem104.elisa](../../../elisa/p/problem104.elisa) |
| Nim | [nim/p/problem104.nim](../../../nim/p/problem104.nim) |
| Odin | [odin/p/problem104.odin](../../../odin/p/problem104.odin) |
| Rust | [rust/p/problem104.rs](../../../rust/p/problem104.rs) |
| V | [v/p/problem104.v](../../../v/p/problem104.v) |
| Zig | [zig/p/problem104.zig](../../../zig/p/problem104.zig) |
