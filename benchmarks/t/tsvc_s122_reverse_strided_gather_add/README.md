# TSVC s122 reverse-strided gather-add

`tsvc_s122_reverse_strided_gather_add` is a bounded, clean-room profile of TSVC `s122`. The destination index starts at `n1-1` and advances by `n3`, while each successive iteration reads the next B value in reverse order. It preserves the source's one-pass A update and the distinct induction variables that derive the two address sequences.

## Contract

The exported symbol is `tsvc_s122_reverse_strided_gather_add` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, n1, n3, A[n], B[n]]`.
- `n` is in `1..32`; `n1` and `n3` are each in `1..n`; exact input length is `3 + 2*n`.
- Every A and B entry is in `[-100,100]`, represented as an integer-valued source `double`. All one-pass sums remain exact in binary64 and fit signed i64.
- Run one ascending source-body sweep: initialize `j=1`, `k=0`; for `i=n1-1; i<n; i+=n3`, perform `k+=j` and `A[i]+=B[n-k]`. Thus destination positions are `n1-1 + t*n3` and B positions are `n-1-t` for iteration `t`. Untouched A positions retain their input values; B is unchanged.
- Output is the complete final A vector as little-endian signed i64 values. Success returns `n` and writes `8*n` bytes. Invalid input returns `-1`; null output or capacity below `8*n` returns `-2` without writes. Input is unchanged.
- `n1=n3=1` reproduces the pinned launcher defaults and walks all A positions while gathering B in reverse. The bounded profile omits TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the body `ntimes` times.

Fixtures include the launcher-default stride pair, a sparse destination progression with reverse sequential gathers, a final-position boundary, malformed stride/shape/range inputs, null pointers, and insufficient output capacity. The independent oracle computes destination and source positions directly instead of duplicating the source's j/k recurrence.

## Source and rights

The codelet is `s122(int n1, int n3)` at lines 1203–1229 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`. In the source `main`, `n1` and `n3` default to 1. The profile exposes both as validated bounded inputs and uses explicit arrays.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s122_reverse_strided_gather_add_oracle.py`](../../tsvc_s122_reverse_strided_gather_add_oracle.py). Suite registration is handled separately.

## Distinction from related packages

The local `tsvc_s353_unrolled_sparse_saxpy` gathers through an explicit index vector and updates contiguous destinations in an explicitly unrolled five-element body. This package derives destinations from a runtime induction-variable stride and pairs them with a sequential reverse gather. `tsvc_indexed_gather_scatter` assigns through explicit indices rather than adding a reverse-stream value to a stride-selected destination.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s122_reverse_strided_gather_add.c`](../../../c/t/tsvc_s122_reverse_strided_gather_add.c) |
| C3 | [`tsvc_s122_reverse_strided_gather_add.c3`](../../../c3/t/tsvc_s122_reverse_strided_gather_add.c3) |
| C++ | [`tsvc_s122_reverse_strided_gather_add.cpp`](../../../cpp/t/tsvc_s122_reverse_strided_gather_add.cpp) |
| Elisa | [`tsvc_s122_reverse_strided_gather_add.elisa`](../../../elisa/t/tsvc_s122_reverse_strided_gather_add.elisa) |
| Nim | [`tsvc_s122_reverse_strided_gather_add.nim`](../../../nim/t/tsvc_s122_reverse_strided_gather_add.nim) |
| Odin | [`tsvc_s122_reverse_strided_gather_add.odin`](../../../odin/t/tsvc_s122_reverse_strided_gather_add.odin) |
| Rust | [`tsvc_s122_reverse_strided_gather_add.rs`](../../../rust/t/tsvc_s122_reverse_strided_gather_add.rs) |
| V | [`tsvc_s122_reverse_strided_gather_add.v`](../../../v/t/tsvc_s122_reverse_strided_gather_add.v) |
| Zig | [`tsvc_s122_reverse_strided_gather_add.zig`](../../../zig/t/tsvc_s122_reverse_strided_gather_add.zig) |
