# Project Euler Problem 33

## Contract

For a digit length in `0..=5`, return the integer value produced by the pinned Python solution after multiplying the reciprocals of all digit-cancelling fractions it finds. Inputs outside the range return `-1`. The source searches two-digit denominators and numerators from 11 up to, but not including, `10 ** digit_len`; when no fractions are found, the initial product remains 1.

The source skips a final zero in the denominator, requires the numerator's last digit to equal the denominator's tens digit, compares the uncancelled and cancelled ratios using floating-point equality, reduces each accepted fraction, multiplies the reciprocals as floating-point values, and truncates the final result to an integer. On this bounded domain, lengths 2 through 5 find the four documented fractions and return 100; lengths 0 and 1 return 1.

Each language exports a C ABI function:

```c
int64_t problem33(int64_t digit_len);
```

## Workload

[`workload.json`](workload.json) covers empty search ranges, each supported digit length, and invalid inputs. The runner reproduces the source's floating-point ratio comparison. The verifier uses exact rational cross multiplication and a reduced rational product as an independent oracle; the bounded source cases produce the same results.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_033/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem33.c](../../../c/p/problem33.c) |
| C3 | [c3/p/problem33.c3](../../../c3/p/problem33.c3) |
| C++ | [cpp/p/problem33.cpp](../../../cpp/p/problem33.cpp) |
| Elisa | [elisa/p/problem33.elisa](../../../elisa/p/problem33.elisa) |
| Nim | [nim/p/problem33.nim](../../../nim/p/problem33.nim) |
| Odin | [odin/p/problem33.odin](../../../odin/p/problem33.odin) |
| Rust | [rust/p/problem33.rs](../../../rust/p/problem33.rs) |
| V | [v/p/problem33.v](../../../v/p/problem33.v) |
| Zig | [zig/p/problem33.zig](../../../zig/p/problem33.zig) |
