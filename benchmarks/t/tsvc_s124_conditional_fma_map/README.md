# TSVC s124 conditional multiply-add map

`tsvc_s124_conditional_fma_map` is a bounded, clean-room profile of TSVC `s124`. Each input position emits exactly one result. If `B[i] > 0`, the result uses B; otherwise, including when B is zero, it uses C. Both branches add the same product `D[i]*E[i]`:

`A[i] = (B[i] if B[i] > 0 else C[i]) + D[i]*E[i]`

This differs from the local `vif` masked assignment, which copies positive B values and otherwise retains A. It also differs from `s161` and `s278`, whose branches update multiple state arrays rather than select one source value for a single output.

## Contract

The exported symbol is `tsvc_s124_conditional_fma_map` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, B[n], C[n], D[n], E[n]]`.
- `n` is in `1..32`; exact input length is `1 + 4*n`.
- Each B, C, D, and E element is in `[-100,100]`, represented as an integer-valued source `double`. The bounded products and sums remain exactly representable in binary64 and fit signed i64.
- Run one source-body pass in ascending i. The branch is strictly `B[i] > 0`; zero follows the C branch. Exactly one output position is written per input.
- Output is the n-element A vector in little-endian signed i64 form. Success returns n and writes `8*n` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Input is unchanged.
- The profile excludes the TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the source body `ntimes` times.

Fixtures cover both branches and the strict-zero boundary, signed values, the one-element boundary, malformed shape/range inputs, null pointers, and insufficient capacity. The independent oracle expresses the branch as a per-element selection rather than reproducing the source's incremented j.

## Source and rights

The codelet is `s124` at lines 1310–1341 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s124_conditional_fma_map_oracle.py`](../../tsvc_s124_conditional_fma_map_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s124_conditional_fma_map.c`](../../../c/t/tsvc_s124_conditional_fma_map.c) |
| C3 | [`tsvc_s124_conditional_fma_map.c3`](../../../c3/t/tsvc_s124_conditional_fma_map.c3) |
| C++ | [`tsvc_s124_conditional_fma_map.cpp`](../../../cpp/t/tsvc_s124_conditional_fma_map.cpp) |
| Elisa | [`tsvc_s124_conditional_fma_map.elisa`](../../../elisa/t/tsvc_s124_conditional_fma_map.elisa) |
| Nim | [`tsvc_s124_conditional_fma_map.nim`](../../../nim/t/tsvc_s124_conditional_fma_map.nim) |
| Odin | [`tsvc_s124_conditional_fma_map.odin`](../../../odin/t/tsvc_s124_conditional_fma_map.odin) |
| Rust | [`tsvc_s124_conditional_fma_map.rs`](../../../rust/t/tsvc_s124_conditional_fma_map.rs) |
| V | [`tsvc_s124_conditional_fma_map.v`](../../../v/t/tsvc_s124_conditional_fma_map.v) |
| Zig | [`tsvc_s124_conditional_fma_map.zig`](../../../zig/t/tsvc_s124_conditional_fma_map.zig) |
