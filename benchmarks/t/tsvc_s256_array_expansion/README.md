# TSVC s256 array expansion

This package is a bounded clean-room profile of TSVC `s256` in the
`Expansion-dbl` launcher family. The source performs a row recurrence for each
matrix column, then combines each updated A value with a row-specific product:

```text
for column in 0..n:
    for row in 1..n:
        A[row] = 1 - A[row - 1]
        C[row][column] = A[row] + B[row][column] * D[row]
```

Because `A[0]` is never changed, each column repeats the same ascending
recurrence while writing its own C cells. The package preserves both the final
A vector and the full C matrix as little-endian signed 64-bit output.

## Contract

The exported symbol is `tsvc_s256_array_expansion`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, A0, D[n], B[n*n], C_initial[n*n]]`, with `n` in 1 through 16.
- `A0` is in `[-1,000, 1,000]`; D and B entries are in `[-1,000, 1,000]`.
- C entries are in `[-1,000,000, 1,000,000]`. Its row zero is preserved; all
  other cells are overwritten by the kernel.
- Source A elements after A0 are omitted from the input because the loop
  overwrites each before reading it. D[0] is accepted but unused, matching the
  source's `row >= 1` loop.
- On success, output `[A_final[n], C_final[n*n]]` as signed little-endian i64
  values and return `n + n*n`.
- Malformed input returns `-1`; a null output or capacity below
  `8*(n+n*n)` bytes returns `-2` without writing output.

The recurrence stays within `[-1,000, 1,001]`, and the matrix update within
`[-1,001,001, 1,001,001]`. All intermediates are exact integers in the source
binary64 domain and signed 64-bit arithmetic. The bounded profile performs one
source-order matrix sweep, omitting the original timing repetitions, dummy
calls, and checker.

## Source and rights

The behavior reference is `s256` in `TSVC/tsc.inc`, lines 2543–2567, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2543). The
[`Expansion-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c)
selects double precision. TSVC comments attribute its non-four-digit codelets
to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*.

No explicit upstream license grant was found in the pinned source or
repository material reviewed. These ports independently implement the bounded
recurrence and matrix update; they reuse no upstream code or comments. No
upstream license or endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s256_array_expansion_oracle.py`](../../tsvc_s256_array_expansion_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s256_array_expansion.c`](../../../c/t/tsvc_s256_array_expansion.c) |
| C3 | [`tsvc_s256_array_expansion.c3`](../../../c3/t/tsvc_s256_array_expansion.c3) |
| C++ | [`tsvc_s256_array_expansion.cpp`](../../../cpp/t/tsvc_s256_array_expansion.cpp) |
| Elisa | [`tsvc_s256_array_expansion.elisa`](../../../elisa/t/tsvc_s256_array_expansion.elisa) |
| Nim | [`tsvc_s256_array_expansion.nim`](../../../nim/t/tsvc_s256_array_expansion.nim) |
| Odin | [`tsvc_s256_array_expansion.odin`](../../../odin/t/tsvc_s256_array_expansion.odin) |
| Rust | [`tsvc_s256_array_expansion.rs`](../../../rust/t/tsvc_s256_array_expansion.rs) |
| V | [`tsvc_s256_array_expansion.v`](../../../v/t/tsvc_s256_array_expansion.v) |
| Zig | [`tsvc_s256_array_expansion.zig`](../../../zig/t/tsvc_s256_array_expansion.zig) |
