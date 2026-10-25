# TSVC s126 matrix column recurrence

`tsvc_s126_matrix_column_recurrence` is a bounded, clean-room profile of the TSVC `s126` induction-variable codelet. It updates each matrix column from top to bottom. Each updated cell reads the preceding row's B value (already updated except for row zero) and adds a coefficient times the corresponding C entry.

## Contract

The exported symbol is `tsvc_s126_matrix_column_recurrence` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, coefficients[n*n], C[n*n], B[n*n]]`, with all matrices row-major.
- `n` is in `2..6`; exact input length is `1 + 3*n*n`.
- Each coefficient, C entry, and initial B entry is in `[-100,100]`, represented as an integer-valued source `double`. The bounded products and recurrence sums remain exact in binary64 and fit signed i64.
- Execute one source-body sweep. Initialize `k=1`; visit columns `i=0..n-1`, then rows `j=1..n-1`, assigning `B[j,i] = B[j-1,i] + coefficients[k-1]*C[j,i]`, incrementing k after each row update and once more after each column. The extra per-column increment intentionally skips the final coefficient position in each n-element coefficient block.
- Output is the complete final B matrix in row-major little-endian signed i64 form. Success returns `n*n` and writes `8*n*n` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Input is unchanged.
- The bounded profile excludes the TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the source body `ntimes` times.

Fixtures include hand-derived 2x2 and 3x3 column recurrences, including the per-column coefficient skip, plus malformed dimensions, short input, out-of-range values, null pointers, and insufficient output capacity. The independent oracle walks rows and columns directly and computes the corresponding coefficient index separately from the source's k recurrence.

## Source and rights

The codelet is `s126` at lines 1375–1404 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s126_matrix_column_recurrence_oracle.py`](../../tsvc_s126_matrix_column_recurrence_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s126_matrix_column_recurrence.c`](../../../c/t/tsvc_s126_matrix_column_recurrence.c) |
| C3 | [`tsvc_s126_matrix_column_recurrence.c3`](../../../c3/t/tsvc_s126_matrix_column_recurrence.c3) |
| C++ | [`tsvc_s126_matrix_column_recurrence.cpp`](../../../cpp/t/tsvc_s126_matrix_column_recurrence.cpp) |
| Elisa | [`tsvc_s126_matrix_column_recurrence.elisa`](../../../elisa/t/tsvc_s126_matrix_column_recurrence.elisa) |
| Nim | [`tsvc_s126_matrix_column_recurrence.nim`](../../../nim/t/tsvc_s126_matrix_column_recurrence.nim) |
| Odin | [`tsvc_s126_matrix_column_recurrence.odin`](../../../odin/t/tsvc_s126_matrix_column_recurrence.odin) |
| Rust | [`tsvc_s126_matrix_column_recurrence.rs`](../../../rust/t/tsvc_s126_matrix_column_recurrence.rs) |
| V | [`tsvc_s126_matrix_column_recurrence.v`](../../../v/t/tsvc_s126_matrix_column_recurrence.v) |
| Zig | [`tsvc_s126_matrix_column_recurrence.zig`](../../../zig/t/tsvc_s126_matrix_column_recurrence.zig) |
