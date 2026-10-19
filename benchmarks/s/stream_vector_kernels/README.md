# Bounded integer STREAM-kernel variant

This package exposes the four STREAM vector kernels through one mode-selected call. It is a bounded integer variant for algorithm comparison; it is not an official STREAM benchmark result and does not measure memory bandwidth or implement STREAM's timing/run rules.

## Contract

The `i64_array_bytes_output` input is mode-specific:

- Mode `0` copies `A`: `[0, n, A...]`.
- Mode `1` scales `A`: `[1, n, alpha, A...]`, computing `alpha * A[i]`.
- Mode `2` adds `A` and `B`: `[2, n, A..., B...]`, computing `A[i] + B[i]`.
- Mode `3` runs the triad: `[3, n, alpha, A..., B...]`, computing `A[i] + alpha * B[i]`.

The exact input length follows the selected mode. `n` is in `0..=128`; every supplied element and `alpha` is in `[-1000, 1000]`. Results are written as `n` little-endian signed i64 values, and success returns `8*n`, the output byte count. The input bounds keep every intermediate and result in signed i64 range, so overflow is impossible for a valid input.

Malformed mode, framing, count, range, or overflow returns `-1`. A null output pointer returns `-2`, including for empty output; a non-null output with capacity zero is sufficient for a valid empty result. A short buffer returns `-2`. Errors write no output.

## Source and attribution

The four operations follow the scalar loops in John D. McCalpin's STREAM source, [`stream/src/stream.c` at `nfinit/ansibench` commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/stream/src/stream.c), Copyright 1991–2013. The corresponding upstream notice is [`stream/LICENSE` at the same commit](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/stream/LICENSE). This bounded integer adaptation changes the data type, sizes, interface, and measurement method. The upstream license permits use and modification; published results from modified source must be clearly labeled as a variant. Use of the name “STREAM benchmark results” is reserved for runs conforming to the STREAM run rules. This package should be identified as a bounded integer STREAM-kernel variant, not as an official STREAM benchmark result.

## Workload and oracle

[`workload.json`](workload.json) covers every operation, empty vectors, bounds, malformed layouts, and output-buffer errors. The independent oracle is [`benchmarks/stream_vector_kernels_oracle.py`](../../stream_vector_kernels_oracle.py).

| Language | Port |
|---|---|
| C | [`c/s/stream_vector_kernels.c`](../../../c/s/stream_vector_kernels.c) |
| C++ | [`cpp/s/stream_vector_kernels.cpp`](../../../cpp/s/stream_vector_kernels.cpp) |
| C3 | [`c3/s/stream_vector_kernels.c3`](../../../c3/s/stream_vector_kernels.c3) |
| Elisa | [`elisa/s/stream_vector_kernels.elisa`](../../../elisa/s/stream_vector_kernels.elisa) |
| Nim | [`nim/s/stream_vector_kernels.nim`](../../../nim/s/stream_vector_kernels.nim) |
| Odin | [`odin/s/stream_vector_kernels.odin`](../../../odin/s/stream_vector_kernels.odin) |
| Rust | [`rust/s/stream_vector_kernels.rs`](../../../rust/s/stream_vector_kernels.rs) |
| V | [`v/s/stream_vector_kernels.v`](../../../v/s/stream_vector_kernels.v) |
| Zig | [`zig/s/stream_vector_kernels.zig`](../../../zig/s/stream_vector_kernels.zig) |
