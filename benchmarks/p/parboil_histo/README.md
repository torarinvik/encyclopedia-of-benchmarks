# Parboil saturating histogram

`parboil_histo` is a bounded profile of Parboil's scalar reference histogram
kernel. It visits each input value and increments its byte-sized bin until the
count reaches 255. Each requested iteration clears the full histogram and
processes the same immutable input again, matching the source loop. This is a
standalone frequency table; the local counting-sort and Otsu packages use
histograms as internal stages but expose different algorithms and outputs.

## Contract

- Exported symbol: `parboil_histo`; ABI: `i64_array_bytes_output`.
- Input is `[iterations, bin_count, sample_count, sample_0, ...]` with exact
  length `3 + sample_count`.
- `iterations` is in `0..8`, `bin_count` in `1..256`, and `sample_count` in
  `0..1024`. Every sample is an integer in `0..bin_count-1`.
- This profile flattens Parboil's dimensions to `img_width=sample_count`,
  `img_height=1`, `histo_width=bin_count`, and `histo_height=1`. The source
  indexes `histo[value]` directly; restricting values below `bin_count`
  supplies the memory-safe input domain that the original reference does not
  validate itself.
- Before every iteration, all active bins are set to zero. Samples are then
  visited in input order, incrementing `histo[value]` only while it is below
  255. With zero iterations, the initially zeroed histogram is returned.
  Repeating one pass yields the same final bytes as repeating several passes,
  but all bounded passes remain in the benchmark computation.
- The output is exactly `bin_count` raw bytes in increasing bin order. The
  function returns that byte count. Invalid input returns `-1`; a null output
  pointer or capacity smaller than `bin_count` returns `-2` without writing.
- The maximum input length is 1027 words and maximum output is 256 bytes.

The independent oracle computes each bin by direct occurrence counting and
does not reproduce the ports' clear-and-increment implementation.
[`workload.json`](workload.json) includes empty/zero-iteration behavior,
multiple iterations, an exact saturation case, invalid values, and ABI errors.

## Source and rights

Pinned source: [`yuhc/gpu-parboil` commit
`ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b).
The scalar kernel is in
[`benchmarks/histo/src/base/main.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/histo/src/base/main.c),
particularly its `numIterations` loop and saturating increment at source lines
85–95. The output image conversion and BMP writer in `util.c` are outside this
profile. The pinned repository provides the Illinois Open Source License;
the complete text is reproduced in [`LICENSE.txt`](LICENSE.txt). These ports
are clean-room implementations of the bounded behavior.

Independent oracle: [`benchmarks/parboil_histo_oracle.py`](../../parboil_histo_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`parboil_histo.c`](../../../c/p/parboil_histo.c) |
| C3 | [`parboil_histo.c3`](../../../c3/p/parboil_histo.c3) |
| C++ | [`parboil_histo.cpp`](../../../cpp/p/parboil_histo.cpp) |
| Elisa | [`parboil_histo.elisa`](../../../elisa/p/parboil_histo.elisa) |
| Nim | [`parboil_histo.nim`](../../../nim/p/parboil_histo.nim) |
| Odin | [`parboil_histo.odin`](../../../odin/p/parboil_histo.odin) |
| Rust | [`parboil_histo.rs`](../../../rust/p/parboil_histo.rs) |
| V | [`parboil_histo.v`](../../../v/p/parboil_histo.v) |
| Zig | [`parboil_histo.zig`](../../../zig/p/parboil_histo.zig) |
