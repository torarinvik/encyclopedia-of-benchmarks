# TSVC s127 fixed pair expansion

`tsvc_s127_fixed_pair_expansion` is a bounded, clean-room profile of TSVC `s127`. For each input position it emits two adjacent values, using the source's multiple-increment induction variable and statement order:

`A[2*i] = B[i] + C[i]*D[i]`

`A[2*i+1] = B[i] + D[i]*E[i]`

This is a fixed two-value expansion: unlike the local TSVC column-compaction codelet, every input always produces two outputs in a stable pair order.

## Contract

The exported symbol is `tsvc_s127_fixed_pair_expansion` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, B[n], C[n], D[n], E[n]]`.
- `n` is in `1..32`; exact input length is `1 + 4*n`.
- Each B, C, D, and E element is in `[-100,100]`, represented as an integer-valued source `double`. The bounded products and sums remain exactly representable in binary64 and fit signed i64.
- Run one source-body pass in ascending i. Starting with `j=-1`, increment j and write `B[i]+C[i]*D[i]`, then increment j again and write `B[i]+D[i]*E[i]`.
- Output is all `2*n` values in interleaved pair order, little-endian signed i64. Success returns `2*n` and writes `16*n` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Input is unchanged.
- The profile excludes the TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the source body `2*ntimes` times.

Fixtures include signed and positive pair computations, the one-item boundary, malformed shape/range inputs, null pointers, and insufficient capacity. The independent oracle builds the two outputs from each input record without reproducing the source's j increments.

## Source and rights

The codelet is `s127` at lines 1408–1436 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s127_fixed_pair_expansion_oracle.py`](../../tsvc_s127_fixed_pair_expansion_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s127_fixed_pair_expansion.c`](../../../c/t/tsvc_s127_fixed_pair_expansion.c) |
| C3 | [`tsvc_s127_fixed_pair_expansion.c3`](../../../c3/t/tsvc_s127_fixed_pair_expansion.c3) |
| C++ | [`tsvc_s127_fixed_pair_expansion.cpp`](../../../cpp/t/tsvc_s127_fixed_pair_expansion.cpp) |
| Elisa | [`tsvc_s127_fixed_pair_expansion.elisa`](../../../elisa/t/tsvc_s127_fixed_pair_expansion.elisa) |
| Nim | [`tsvc_s127_fixed_pair_expansion.nim`](../../../nim/t/tsvc_s127_fixed_pair_expansion.nim) |
| Odin | [`tsvc_s127_fixed_pair_expansion.odin`](../../../odin/t/tsvc_s127_fixed_pair_expansion.odin) |
| Rust | [`tsvc_s127_fixed_pair_expansion.rs`](../../../rust/t/tsvc_s127_fixed_pair_expansion.rs) |
| V | [`tsvc_s127_fixed_pair_expansion.v`](../../../v/t/tsvc_s127_fixed_pair_expansion.v) |
| Zig | [`tsvc_s127_fixed_pair_expansion.zig`](../../../zig/t/tsvc_s127_fixed_pair_expansion.zig) |
