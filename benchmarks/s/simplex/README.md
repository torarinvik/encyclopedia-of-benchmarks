# Simplex tableau solver

This package ports the pinned Python tableau simplex implementation with bounded dimensions and micro-scaled inputs. In the no-artificial case, row 0 is the objective and rows 1 onward are constraints. With artificial variables, row 0 is the phase-I objective, row 1 is the original objective, and rows 2 onward are constraints. The phase-I transition removes its objective row and the artificial columns immediately before the RHS.

## Contract

Input is `[n_vars, n_artificial, n_rows, n_cols, tableau_micro...]`; tableau values are divided by 1,000,000. Bounds are 2–4 variables, 0–2 artificial variables, 3–8 rows, and at most 16 columns, with at least `n_vars+n_artificial+1` columns. The flattened tableau must have exactly `n_rows*n_cols` values, all RHS values must be nonnegative, and the source iteration limit is 100. Pivot selection follows the source objective-row argmax and positive-ratio constraint rule. A missing positive-ratio candidate, non-finite intermediate, unsupported shape, or non-convergence returns `-1e300`; the result is `abs(final_tableau[0,-1])`.

Pinned source: [simplex.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_programming/simplex.py). See [workload](workload.json) and [oracle](../../simplex_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/simplex.c |
| C3 | ../../../c3/s/simplex.c3 |
| C++ | ../../../cpp/s/simplex.cpp |
| Elisa | ../../../elisa/s/simplex.elisa |
| Nim | ../../../nim/s/simplex.nim |
| Odin | ../../../odin/s/simplex.odin |
| Rust | ../../../rust/s/simplex.rs |
| V | ../../../v/s/simplex.v |
| Zig | ../../../zig/s/simplex.zig |

