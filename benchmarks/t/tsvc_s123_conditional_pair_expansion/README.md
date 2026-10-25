# TSVC s123 conditional pair expansion

`tsvc_s123_conditional_pair_expansion` is a bounded, clean-room profile of TSVC `s123`. Every input position emits one baseline value, and positions with positive C emit a second value immediately after it:

- Always append `B[i] + D[i]*E[i]`.
- If `C[i] > 0`, then append `C[i] + D[i]*E[i]`.

The result is a stable variable-length expansion with output count from n through 2n. Unlike s127's fixed pair expansion, this codelet's second output depends on C; unlike s343's compaction, no input position is omitted.

## Contract

The exported symbol is `tsvc_s123_conditional_pair_expansion` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, B[n], C[n], D[n], E[n]]`.
- `n` is in `1..32`; exact input length is `1 + 4*n`.
- Each B, C, D, and E element is in `[-100,100]`, represented as an integer-valued source `double`. The bounded products and sums remain exactly representable in binary64 and fit signed i64.
- Run one source-body pass in ascending i. Append the baseline first; if and only if C[i] is strictly positive, append the C-based value second.
- Output is the written prefix as little-endian signed i64 values. Success returns the actual output count and writes `8*count` bytes. The caller must provide worst-case capacity of at least `16*n` bytes, matching the source A array's 2n output slots. Invalid input returns `-1`; null output or capacity below `16*n` returns `-2` without writes. Input is unchanged.
- The profile excludes timing, initialization, dummy-call, and checksum wrappers and does not repeat the body `ntimes` times.

Fixtures cover all-positive, mixed, zero, and negative C predicates, the one-element boundary, malformed shape/range inputs, null pointers, and insufficient worst-case capacity. The independent oracle appends values to a dynamic result list and does not reproduce the source's j induction variable.

## Source and rights

The codelet is `s123` at lines 1275–1306 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s123_conditional_pair_expansion_oracle.py`](../../tsvc_s123_conditional_pair_expansion_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s123_conditional_pair_expansion.c`](../../../c/t/tsvc_s123_conditional_pair_expansion.c) |
| C3 | [`tsvc_s123_conditional_pair_expansion.c3`](../../../c3/t/tsvc_s123_conditional_pair_expansion.c3) |
| C++ | [`tsvc_s123_conditional_pair_expansion.cpp`](../../../cpp/t/tsvc_s123_conditional_pair_expansion.cpp) |
| Elisa | [`tsvc_s123_conditional_pair_expansion.elisa`](../../../elisa/t/tsvc_s123_conditional_pair_expansion.elisa) |
| Nim | [`tsvc_s123_conditional_pair_expansion.nim`](../../../nim/t/tsvc_s123_conditional_pair_expansion.nim) |
| Odin | [`tsvc_s123_conditional_pair_expansion.odin`](../../../odin/t/tsvc_s123_conditional_pair_expansion.odin) |
| Rust | [`tsvc_s123_conditional_pair_expansion.rs`](../../../rust/t/tsvc_s123_conditional_pair_expansion.rs) |
| V | [`tsvc_s123_conditional_pair_expansion.v`](../../../v/t/tsvc_s123_conditional_pair_expansion.v) |
| Zig | [`tsvc_s123_conditional_pair_expansion.zig`](../../../zig/t/tsvc_s123_conditional_pair_expansion.zig) |
