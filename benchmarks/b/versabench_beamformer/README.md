# `versabench_beamformer`

This package isolates VersaBench's 12-channel complex `BeamForm` stage from the pinned `beamformer.c`. For each channel it multiplies the complex weight by the complex input and accumulates the real and imaginary components in ascending channel order using binary32 arithmetic. The adapter accepts weights and samples as binary64 transport values, narrows each to the source's `float`, and returns the two binary32 results promoted to binary64.

This is a bounded beamforming-stage kernel. It does not implement the preceding FIR decimators, magnitude detector, output formatting, or the launcher's 25/400 full-pipeline iterations; the source explicitly marks its optional `COARSE` decimation path as unimplemented.

## Contract

- Export `versabench_beamformer` with the `float64_slice_io` ABI.
- Input contains exactly 48 finite binary64 values, four per channel in this order: `[weight_real, weight_imaginary, sample_real, sample_imaginary]`, for 12 channels. Each value must be in `[-128, 128]` before narrowing to binary32.
- Output contains `[real_sum, imaginary_sum]`, each the source-order binary32 accumulator promoted to binary64. Success returns `2` output elements. Invalid input returns `-1`; a null output pointer or capacity below 2 returns `-2` without writing.
- The real update is `sum_re += weight_re * sample_re - weight_im * sample_im`; the imaginary update is `sum_im += weight_re * sample_im + weight_im * sample_re`. Operations are kept in ascending channel order without fused multiply-add.

The workload covers zero input, exact complex products, accumulation, invalid length/range, and output-buffer errors. The independent [oracle](../../versabench_beamformer_oracle.py) rounds each operation to binary32.

## Pinned source

[`VersaBench/beamformer/beamformer.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/beamformer/beamformer.c) at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, especially `BeamForm`. The pinned launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/beamformer/info.sh), which selects `-i 25` for the small profile and `-i 400` otherwise. The source copyright and permission notice is included in [LICENSE](LICENSE).

## Language ports

| Language | Source |
|---|---|
| C | [c/b/versabench_beamformer.c](../../../c/b/versabench_beamformer.c) |
| C3 | [c3/b/versabench_beamformer.c3](../../../c3/b/versabench_beamformer.c3) |
| C++ | [cpp/b/versabench_beamformer.cpp](../../../cpp/b/versabench_beamformer.cpp) |
| Elisa | [elisa/b/versabench_beamformer.elisa](../../../elisa/b/versabench_beamformer.elisa) |
| Nim | [nim/b/versabench_beamformer.nim](../../../nim/b/versabench_beamformer.nim) |
| Odin | [odin/b/versabench_beamformer.odin](../../../odin/b/versabench_beamformer.odin) |
| Rust | [rust/b/versabench_beamformer.rs](../../../rust/b/versabench_beamformer.rs) |
| V | [v/b/versabench_beamformer.v](../../../v/b/versabench_beamformer.v) |
| Zig | [zig/b/versabench_beamformer.zig](../../../zig/b/versabench_beamformer.zig) |
