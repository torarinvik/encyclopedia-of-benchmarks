# Doubly-even magic square by diagonal complements

Construct the normal magic square for an order divisible by four. The Rosetta Code task title identified an order class absent from the local odd-order Siamese and singly-even Strachey profiles. The contract below pins the classical 4×4 diagonal-complement construction rather than any published implementation.

## Contract

- `scalar_call` accepts a signed 64-bit order `n`.
- Valid orders are multiples of four from 4 through 64. Other inputs return `-1`.
- Visit cells in row-major order, starting with the sequence `1..n²`. Within every aligned 4×4 block, replace each value on either block diagonal with `n² + 1 - value`. Equivalently, complement a cell when its row and column have equal residues modulo four, or when those residues sum to three.
- Return the low 63 bits of FNV-1a-64 over the order as one unsigned byte followed by the generated cells as signed 32-bit little-endian integers. Use offset `0xcbf29ce484222325`, prime `0x100000001b3`, and 64-bit wraparound.

The ports generate and hash each cell directly, so the kernel uses no scratch array. The largest order has 4,096 cells and a maximum cell value of 4,096; its magic constant and all loop/index calculations fit signed 32-bit integers.

## Workload and references

[`workload.json`](workload.json) covers several valid order classes and invalid boundaries. The primary oracle applies the two diagonal-residue conditions cell by cell. The independent oracle selects complements from a four-row bit-mask table, materializes the square, checks the normal-square invariants, and then hashes it. The workload declares both expected-result providers so the runner can compare their values without storing copied task examples.

- [Magic Square, CRC Concise Encyclopedia of Mathematics](https://archive.lib.msu.edu/crcmath/math/math/m/m029.htm) describes filling consecutive values and complementing the cells crossed by the diagonals of each 4×4 block.
- [How to Construct a Doubly-Even Magic Square](https://schoolbag.info/mathematics/numbers/58.html) explains the `n²+1` complement rule and its repetition over 4×4 blocks.
- [Rosetta Code task title](https://rosettacode.org/wiki/Magic_squares_of_doubly_even_order) was used only to discover the benchmark gap; no task wording, code, tests, or sample outputs were reused.

Ten source ports use the scalar-call ABI and live in their languages' `m` folders. `check_inventory.py` verifies package file presence and metadata only; it does not execute implementations or references. The shared scalar runner and independent verifier generate expected results dynamically from both references. The package and catalog are registered; no programs, tests, scripts, helpers, checkers, builds, compilers, profilers, or benchmarks have been run.
