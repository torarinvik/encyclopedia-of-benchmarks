# Simultaneous linear equation solver

This package ports the pinned recursive elimination routine with bounded integer-milli coefficients. The source may move one fully nonzero augmented row to the front when a zero appears, then eliminates recursively from row 0 and column 0 without later pivot search. This ABI rejects zero leading pivots, singular or non-finite paths, malformed matrices, and solutions that cannot be represented in signed i64 ticks.

## Contract

Input is `[n, augmented[n*(n+1)]_milli...]`, with `n=1..5`, row-major augmented rows, and each entry divided by 1,000. Entries are bounded to [-100,100] and the packed input length must be exactly `1+n*(n+1)`. Each solution is rounded to five decimal places with Python `round(value, 5)` ties-to-even semantics, then emitted as a signed i64 tick at scale 100,000. The ports resolve exact halfway cases using a fused multiply-add residual before writing the tick. Output starts with `n`; maximum output is 48 bytes. Invalid input or unsupported solve paths return -1; a null output or insufficient capacity returns -2 without writing.

Pinned source: [simultaneous_linear_equation_solver.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/simultaneous_linear_equation_solver.py). See [workload](workload.json) and [oracle](../../simultaneous_linear_equation_solver_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/simultaneous_linear_equation_solver.c |
| C3 | ../../../c3/s/simultaneous_linear_equation_solver.c3 |
| C++ | ../../../cpp/s/simultaneous_linear_equation_solver.cpp |
| Elisa | ../../../elisa/s/simultaneous_linear_equation_solver.elisa |
| Nim | ../../../nim/s/simultaneous_linear_equation_solver.nim |
| Odin | ../../../odin/s/simultaneous_linear_equation_solver.odin |
| Rust | ../../../rust/s/simultaneous_linear_equation_solver.rs |
| V | ../../../v/s/simultaneous_linear_equation_solver.v |
| Zig | ../../../zig/s/simultaneous_linear_equation_solver.zig |

