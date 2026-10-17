# Polynomial addition

This benchmark ports the pinned C linked-list merge for adding two polynomials. Each input polynomial is supplied in descending degree order, and the output keeps that order.

## Contract

The i64_array_bytes_output input is [nA, coefficientA0, degreeA0, ..., coefficientA(nA-1), degreeA(nA-1), nB, coefficientB0, degreeB0, ..., coefficientB(nB-1), degreeB(nB-1)]. Counts nA and nB are each 1 through 16. The complete input has exactly 2 + 2*(nA+nB) values; the parser admits 67 values to reject a trailing element after the maximum valid 66-value input.

Each polynomial is nonempty, coefficients are in [-1,000,000, 1,000,000], and degrees are in [0, 63]. The implementation validates that degrees are strictly descending and unique within each polynomial. Invalid counts, framing, ordering, or numeric bounds return -1.

The merge takes the term with the larger degree. Equal degrees produce one term whose coefficient is the sum, including zero when coefficients cancel. Remaining terms are appended in order. Output is the unprefixed sequence of signed 64-bit little-endian (coefficient, degree) pairs. The scalar return is bytes written, at most 512. A null output pointer or insufficient capacity returns -2 before writing.

The source does not handle an empty polynomial safely: its result dummy node has uninitialized coefficient and degree fields if the merge starts with an empty operand. Empty inputs are excluded by the contract. With bounded counts and values, all coefficient sums and output arithmetic fit signed 64-bit integers.

## Pinned source and workload

The source is [TheAlgorithms/C poly_add.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/poly_add.c) at commit e5dad3fa8def3726ec850ca66a7f51521f8ad393. The workload includes the source examples, disjoint and matching degrees, zero-sum cancellation, maximum output, malformed counts/order/ranges, and a short-buffer case. The independent oracle is in benchmarks/poly_add_oracle.py.

## Implementations

| Language | Source |
| --- | --- |
| C | c/p/poly_add.c |
| C3 | c3/p/poly_add.c3 |
| C++ | cpp/p/poly_add.cpp |
| Elisa | elisa/p/poly_add.elisa |
| Nim | nim/p/poly_add.nim |
| Odin | odin/p/poly_add.odin |
| Rust | rust/p/poly_add.rs |
| V | v/p/poly_add.v |
| Zig | zig/p/poly_add.zig |
