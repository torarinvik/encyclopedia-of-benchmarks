# TSVC s351 direct unrolled SAXPY

This bounded profile implements the LoopRerolling `s351` kernel as a direct-index SAXPY. For each consecutive group of five, it performs the five source-ordered updates `A[i+k] += alpha * B[i+k]` for `k=0..4`. Unlike `s353`, it reads B at the same index and does not gather through an index vector.

## Contract

The exported symbol is `tsvc_s351_direct_unrolled_saxpy`, using `float64_slice_io`.

- Input is `[n, alpha, A[n], B[n]]` with `n` in `5..40`, a multiple of five.
- `alpha`, A, and B are finite integer-valued binary64 numbers in `[-1,1]`.
- One ascending sweep processes groups of five in source order. Each output is `A[i] + alpha*B[i]`; input remains unchanged.
- Return the complete final A vector. Invalid input returns `-1`; null output or capacity below n returns `-2`, without writes.
- The maximum output magnitude is 2, exactly representable in binary32 and binary64.

The explicit inputs replace TSVC's initializer, which sets A and B to one and `alpha=C[0]` to one. The timed repetition loop, dummy call, and checksum wrapper are excluded. The fixed workloads include source-shaped default values, signed values, and a ten-element two-group case.

## Source and rights

Pinned source: `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, `s351` (lines 4071–4098), selected by `TSVC/LoopRerolling-dbl/info.sh` and `TSVC/LoopRerolling-flt/info.sh`. The five explicit statements update contiguous A and B positions using `alpha=C[0]`. `s353` is related but uses `B[ip[i]]`; its sparse gather operation remains a separate package. TSVC attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine. No explicit upstream modification or redistribution grant was found; these are clean-room ports and claim no upstream license. See `LICENSE.txt`.

The oracle is [`benchmarks/tsvc_s351_direct_unrolled_saxpy_oracle.py`](../../tsvc_s351_direct_unrolled_saxpy_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s351_direct_unrolled_saxpy.c`](../../../c/t/tsvc_s351_direct_unrolled_saxpy.c) |
| C3 | [`tsvc_s351_direct_unrolled_saxpy.c3`](../../../c3/t/tsvc_s351_direct_unrolled_saxpy.c3) |
| C++ | [`tsvc_s351_direct_unrolled_saxpy.cpp`](../../../cpp/t/tsvc_s351_direct_unrolled_saxpy.cpp) |
| Elisa | [`tsvc_s351_direct_unrolled_saxpy.elisa`](../../../elisa/t/tsvc_s351_direct_unrolled_saxpy.elisa) |
| Nim | [`tsvc_s351_direct_unrolled_saxpy.nim`](../../../nim/t/tsvc_s351_direct_unrolled_saxpy.nim) |
| Odin | [`tsvc_s351_direct_unrolled_saxpy.odin`](../../../odin/t/tsvc_s351_direct_unrolled_saxpy.odin) |
| Rust | [`tsvc_s351_direct_unrolled_saxpy.rs`](../../../rust/t/tsvc_s351_direct_unrolled_saxpy.rs) |
| V | [`tsvc_s351_direct_unrolled_saxpy.v`](../../../v/t/tsvc_s351_direct_unrolled_saxpy.v) |
| Zig | [`tsvc_s351_direct_unrolled_saxpy.zig`](../../../zig/t/tsvc_s351_direct_unrolled_saxpy.zig) |
