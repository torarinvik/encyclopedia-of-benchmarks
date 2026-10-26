# Quine–McCluskey Two-Level Boolean Minimization

This package implements the exact Quine–McCluskey method described in the Encyclopedia of Algorithms, DOI suffix 446. It is distinct from [mallocbench_espresso](../../m/mallocbench_espresso/README.md), which profiles a bounded heuristic EXPAND/IRREDUNDANT sequence rather than globally optimal prime-implicant cover selection.

## Contract

- ABI: i64_array_bytes_output; symbol: quine_mccluskey_minimization.
- Input is [n, status[2^n]], with 1 <= n <= 3; minterms are listed in ascending binary index. Status 0 means OFF, 1 means ON, and 2 means don't-care.
- Generate every prime implicant that covers at least one ON minterm and no OFF minterm. Select a cover minimizing the number of prime implicants, then total literal count. Remaining ties use the lexicographically smallest sorted (care_mask,value_mask) sequence.
- Output is [term_count, care_mask_0,value_mask_0,...] as little-endian signed i64 words. A minterm m is in a term iff (m & care_mask) == value_mask. An empty ON-set returns [0].
- Invalid input returns -1. A null or short output buffer returns -2 without writes. The maximum input is 9 integers; up to 8 terms fit in 136 output bytes.

The chapter explains Quine–McCluskey's two phases: prime-implicant generation by repeated merging, then minimum-cardinality unate cover selection with literal-count tie-breaking. This clean-room profile enumerates the bounded cube lattice and solves the same two-stage objective exactly. See [RIGHTS.md](RIGHTS.md) for attribution.

## Workload and independent check

[workload.json](workload.json) covers constants, minterm merging, don't-cares, multi-term covers, the maximum variable count, malformed statuses/framing, and output errors. The primary [oracle](../../quine_mccluskey_minimization_oracle.py) uses prime implicants and dynamic programming over ON-set masks. The independent [verifier](../../quine_mccluskey_minimization_verifier_oracle.py) searches legal cubes recursively by uncovered minterm and ranks complete covers.

## Implementations

| Language | Port |
|---|---|
| C | [c/o/quine_mccluskey_minimization.c](../../../c/o/quine_mccluskey_minimization.c) |
| C3 | [c3/o/quine_mccluskey_minimization.c3](../../../c3/o/quine_mccluskey_minimization.c3) |
| C++ | [cpp/o/quine_mccluskey_minimization.cpp](../../../cpp/o/quine_mccluskey_minimization.cpp) |
| Elisa | [elisa/o/quine_mccluskey_minimization.elisa](../../../elisa/o/quine_mccluskey_minimization.elisa) |
| Nim | [nim/o/quine_mccluskey_minimization.nim](../../../nim/o/quine_mccluskey_minimization.nim) |
| Odin | [odin/o/quine_mccluskey_minimization.odin](../../../odin/o/quine_mccluskey_minimization.odin) |
| Rust | [rust/o/quine_mccluskey_minimization.rs](../../../rust/o/quine_mccluskey_minimization.rs) |
| V | [v/o/quine_mccluskey_minimization.v](../../../v/o/quine_mccluskey_minimization.v) |
| Zig | [zig/o/quine_mccluskey_minimization.zig](../../../zig/o/quine_mccluskey_minimization.zig) |

