# TSVC s128 strided coupled update

`tsvc_s128_strided_coupled_update` is a bounded, clean-room profile of TSVC `s128`. The source carries two induction variables so each iteration reads and rewrites the next even B position while producing one A value. Odd B positions are untouched.

## Contract

The exported symbol is `tsvc_s128_strided_coupled_update` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, B[2*n], C[2*n], D[n]]`, with B and C in row-major source order (one-dimensional vectors).
- `n` is in `1..16`; exact input length is `1 + 5*n`.
- Every B, C, and D element is in `[-100,100]`, represented as an integer-valued source `double`. All one-pass intermediate values remain exact in binary64 and fit signed i64.
- Run one source-body pass in ascending i: set `k=j+1` from `j` initially `-1`, assign `A[i]=B[k]-D[i]`, then set `j=k+1` and assign `B[k]=A[i]+C[k]`. Thus `k=2*i`; only even B entries are rewritten, and each A entry observes the B value before that position is rewritten.
- Output is final A followed by the full final B vector, both as little-endian signed i64. Success returns `3*n` values and writes `24*n` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Input is unchanged.
- The profile excludes the TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the source body `2*ntimes` times.

Fixtures cover a source-shaped even-stride update, signed values, the one-element boundary, malformed shape/range data, null input/output, and insufficient capacity. The independent oracle derives the even-index mapping directly rather than reproducing the source induction-variable updates.

## Source and rights

The codelet is `s128` at lines 1440–1469 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s128_strided_coupled_update_oracle.py`](../../tsvc_s128_strided_coupled_update_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s128_strided_coupled_update.c`](../../../c/t/tsvc_s128_strided_coupled_update.c) |
| C3 | [`tsvc_s128_strided_coupled_update.c3`](../../../c3/t/tsvc_s128_strided_coupled_update.c3) |
| C++ | [`tsvc_s128_strided_coupled_update.cpp`](../../../cpp/t/tsvc_s128_strided_coupled_update.cpp) |
| Elisa | [`tsvc_s128_strided_coupled_update.elisa`](../../../elisa/t/tsvc_s128_strided_coupled_update.elisa) |
| Nim | [`tsvc_s128_strided_coupled_update.nim`](../../../nim/t/tsvc_s128_strided_coupled_update.nim) |
| Odin | [`tsvc_s128_strided_coupled_update.odin`](../../../odin/t/tsvc_s128_strided_coupled_update.odin) |
| Rust | [`tsvc_s128_strided_coupled_update.rs`](../../../rust/t/tsvc_s128_strided_coupled_update.rs) |
| V | [`tsvc_s128_strided_coupled_update.v`](../../../v/t/tsvc_s128_strided_coupled_update.v) |
| Zig | [`tsvc_s128_strided_coupled_update.zig`](../../../zig/t/tsvc_s128_strided_coupled_update.zig) |
