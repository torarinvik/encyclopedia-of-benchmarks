# TSVC s257 column-coupled update

This package isolates the `s257` codelet from the pending TSVC
`Expansion-dbl` launcher. It updates one scalar array and a row-major matrix in
place. For a fixed column `i`, each successive matrix row overwrites the same
`A[i]`; that value is then used by the next row. The final value carries into
the next column through `A[i-1]`. This matrix/scalar dependency pattern is
distinct from the local stencil, compaction, and vector update kernels.

## Contract

The ABI is `tsvc_s257_column_coupled_update` with `i64_array_scalar_call`
framing:

- Input: `[n, passes, A[0..n), AA row-major n*n, BB row-major n*n]`.
- `n` is in `2..8`; `passes` is in `1..4`; the exact input length is
  `2 + n + 2*n*n`.
- `A`, `AA`, and `BB` entries are in `[-1,1]`; invalid input returns `-1`.
- For each pass, visit `i=1..n-1` in ascending order, then `j=0..n-1` in
  ascending order. At each step set `A[i]=AA[j,i]-A[i-1]`, then
  `AA[j,i]=A[i]+BB[j,i]`. These writes are visible immediately, as in the
  source loop.
- Return the sum of the final `A` and `AA` entries. `BB` is unchanged and is
  not included. The input buffer is preserved.

The source uses `double`; the selected integer-valued bounds keep every
intermediate exactly representable in binary64 and safely within signed i64.
The package uses up to four source-shaped passes; the launcher repetition and
its timing/dummy-call scaffolding are outside this bounded workload.

## Source and rights

The source is `s257` in
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2689)
at pinned LAC-DCC Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; it is included by
[`TSVC/Expansion-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c).
The launcher is
[`TSVC/Expansion-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/info.sh);
it compiles `dummy.c` and `tsc.c` with `-std=gnu99 -lm` and runs with
`4160 14`. The suite's `s257` uses a 256-by-256 matrix and
`10*(ntimes/LEN2)` repetitions, which is 160 passes for this launcher profile.
This package bounds dimensions to eight and passes to four for a portable
source-shaped profile.

The TSVC source comment attributes the non-four-digit codelets to David
Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*. No explicit license grant was found in the pinned TSVC source or
repository material reviewed. These ports are independent implementations of
the documented loop behavior and reuse no upstream source text or comments. No
upstream license or endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt)
for the rights note.

## Workload and oracle

[`workload.json`](workload.json) distinguishes one pass from retained
multi-pass matrix writes and includes malformed-input cases. The independent
oracle is
[`tsvc_s257_column_coupled_update_oracle.py`](../../tsvc_s257_column_coupled_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s257_column_coupled_update.c`](../../../c/t/tsvc_s257_column_coupled_update.c) |
| C3 | [`tsvc_s257_column_coupled_update.c3`](../../../c3/t/tsvc_s257_column_coupled_update.c3) |
| C++ | [`tsvc_s257_column_coupled_update.cpp`](../../../cpp/t/tsvc_s257_column_coupled_update.cpp) |
| Elisa | [`tsvc_s257_column_coupled_update.elisa`](../../../elisa/t/tsvc_s257_column_coupled_update.elisa) |
| Nim | [`tsvc_s257_column_coupled_update.nim`](../../../nim/t/tsvc_s257_column_coupled_update.nim) |
| Odin | [`tsvc_s257_column_coupled_update.odin`](../../../odin/t/tsvc_s257_column_coupled_update.odin) |
| Rust | [`tsvc_s257_column_coupled_update.rs`](../../../rust/t/tsvc_s257_column_coupled_update.rs) |
| V | [`tsvc_s257_column_coupled_update.v`](../../../v/t/tsvc_s257_column_coupled_update.v) |
| Zig | [`tsvc_s257_column_coupled_update.zig`](../../../zig/t/tsvc_s257_column_coupled_update.zig) |
