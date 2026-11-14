# Standard Young-tableau count by hook lengths

Given a partition, this benchmark counts its standard Young tableaux modulo
998244353 using the hook-length formula. It is distinct from
[`integer_partition`](../../i/integer_partition/README.md), which counts
partitions of an integer rather than tableaux of a supplied shape.

## Draft contract

The intended `i64_array_scalar` input is `[r, lambda_0, ..., lambda_(r-1)]`.
There may be 0 through 65,536 rows; nonempty row lengths are positive,
nonincreasing, and at most 1,000,000. The sum of row lengths may not exceed
1,000,000. The empty partition has count 1. Invalid framing or values return
`-1`; valid input returns the count modulo 998244353.

For each cell, its hook length is one plus the number of cells to its right
and below. Multiply all hook lengths modulo the prime, compute the factorial
of the total number of cells, and multiply by the hook product's modular
inverse. Since every hook length is at most one million, all are nonzero
modulo the prime. Scanning columns while decreasing their heights takes
O(r + N + log p) time and O(r) space for N cells and modulus p.

## Provenance and status

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1418)
identified the counting problem. This package independently states its own
bounded contract and implements the classical hook-length formula; the issue
is an idea index and its text, tests and implementation are not reused.

Draft implementations now exist for C, C3, C++, Elisa, Mojo, Nim, Odin, Rust,
V and Zig, together with a row-oriented oracle and hand-derived fixtures in
[`workload.json`](workload.json). The scalar runner and verifier contain draft
registration and source-presence checks. A separate removable-corner recurrence
provides exact counts for small shapes; the verifier draft also covers both
the maximum cell count and maximum row count. No program, build, compiler or
test has been run, and the drafts' compatibility and results remain unverified.
