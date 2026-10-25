# MediaBench MPEG-2 motion-vector component decode

This package isolates `decode_motion_vector`'s scalar component update in the MPEG Software Simulation Group decoder. Given a predictor, motion-code value, and residual bits, it computes the signed motion-vector delta and wraps the result into the MPEG vector interval. The profile fixes `full_pel_vector=0` (the MPEG-2 path); it does not decode VLCs or consume a bitstream.

## Contract

ABI: `i64_array_bytes_output`; exported symbol: `mediabench_mpeg2_motion_vector_component`.

Input is exactly `[predictor, r_size, motion_code, motion_residual]`. `r_size` is 0–6, `motion_code` is -16–16, and the predictor must be in `[-lim, lim-1]`, where `lim = 16 << r_size`. If `motion_code==0` or `r_size==0`, residual must be zero; otherwise it must be in `[0, 2^r_size-1]`. For positive code, add `((motion_code-1)<<r_size)+residual+1`, then subtract `2*lim` if the result is at least `lim`. For negative code, subtract `((-motion_code-1)<<r_size)+residual+1`, then add `2*lim` if the result is below `-lim`. Zero code leaves the predictor unchanged. The result is one signed i64 in little-endian bytes; success returns 8, malformed input returns `-1`, and null/short output returns `-2`. Validation precedes output-capacity checks and errors do not write output.

This component profile excludes motion-code VLC parsing, residual bitstream reads, predictor-array selection/update, MPEG-1 full-pel scaling, dual-prime arithmetic, reference-frame interpolation, and the decoder pipeline.

## Source and rights

Source: [`mediabench/mpeg2/mpeg2dec/motion.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/mpeg2/mpeg2dec/motion.c), pinned to `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; symbol: `decode_motion_vector`. Launcher: [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/mpeg2/mpeg2dec/info.sh). The source states Copyright (C) 1996, MPEG Software Simulation Group and describes the code as available without license fee or royalty on an “as is” basis, while disclaiming third-party patent status and noting patent royalties for commercial MPEG implementations. The pinned source does not state an explicit source-code redistribution license. These ports are clean-room implementations of the mathematical operation and contain no copied upstream code or comments; see [`NOTICE.txt`](NOTICE.txt) for the rights caveat.

Independent oracle: [`mediabench_mpeg2_motion_vector_component_oracle.py`](../../mediabench_mpeg2_motion_vector_component_oracle.py). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/m/mediabench_mpeg2_motion_vector_component.c`](../../../c/m/mediabench_mpeg2_motion_vector_component.c)
- C3: [`c3/m/mediabench_mpeg2_motion_vector_component.c3`](../../../c3/m/mediabench_mpeg2_motion_vector_component.c3)
- C++: [`cpp/m/mediabench_mpeg2_motion_vector_component.cpp`](../../../cpp/m/mediabench_mpeg2_motion_vector_component.cpp)
- Elisa: [`elisa/m/mediabench_mpeg2_motion_vector_component.elisa`](../../../elisa/m/mediabench_mpeg2_motion_vector_component.elisa)
- Nim: [`nim/m/mediabench_mpeg2_motion_vector_component.nim`](../../../nim/m/mediabench_mpeg2_motion_vector_component.nim)
- Odin: [`odin/m/mediabench_mpeg2_motion_vector_component.odin`](../../../odin/m/mediabench_mpeg2_motion_vector_component.odin)
- Rust: [`rust/m/mediabench_mpeg2_motion_vector_component.rs`](../../../rust/m/mediabench_mpeg2_motion_vector_component.rs)
- V: [`v/m/mediabench_mpeg2_motion_vector_component.v`](../../../v/m/mediabench_mpeg2_motion_vector_component.v)
- Zig: [`zig/m/mediabench_mpeg2_motion_vector_component.zig`](../../../zig/m/mediabench_mpeg2_motion_vector_component.zig)
