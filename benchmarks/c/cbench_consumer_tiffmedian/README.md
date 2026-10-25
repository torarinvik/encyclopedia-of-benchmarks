# cBench `consumer_tiffmedian`: bounded median-cut palette construction

This package isolates the palette-building core of the pinned cBench `consumer_tiffmedian` program. It builds a 5-bit-per-channel RGB histogram, repeatedly bisects the eligible box with the greatest population along its longest channel range at the population median, contracts both boxes to occupied bins, and emits each box's endpoint midpoint as an 8-bit RGB palette entry. New boxes are placed at the front of the palette, matching the source's box-list order.

## Bounded contract

The ABI is `cbench_consumer_tiffmedian` with `i64_array_bytes_output` framing:

- Input: `[palette_limit, pixel_count, r0, g0, b0, ...]`.
- `palette_limit` is 1–8; `pixel_count` is 1–16; each RGB component is 0–255.
- Input length must be exactly `2 + 3*pixel_count` (maximum 50 values).
- Output bytes: `[actual_palette_count, R0, G0, B0, ...]` in source box-list order. For each channel the emitted representative is `4*(minimum_5_bit_bin + maximum_5_bit_bin)`, the source's integer midpoint rule.
- Success returns the output byte count, from 4 through 25. Invalid input returns -1. Null output or insufficient capacity returns -2 without writes.

This bounded profile ends after palette construction. The TIFF reader/writer, TIFF metadata, scanline rendering, the source's cell-accelerated pixel-to-palette lookup, and optional Floyd–Steinberg path are outside the contract. The pinned launcher has no `-f` flag, so this corresponds to its nondithered palette-building path. The oracle implements weighted boxes over a sparse histogram independently of the fixed 32³ histogram layout in the ports.

## Provenance and licensing status

- Pinned benchmark source: [`tiffmedian.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiffmedian/src/tiffmedian.c), symbol `splitbox` and its palette construction path, from `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
- Pinned launcher: [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiffmedian/src/info.sh), with no runtime options. The source comments cite Paul Heckbert, “Color Image Quantization for Frame Buffer Display,” SIGGRAPH '82, pp. 297–307.
- The pinned `tiffmedian.c` file has no explicit license grant in its own text, and this package does not infer or claim one. These ports are clean-room implementations of the abstract median-cut behavior; no upstream source code or comments are copied. The separate notice in bundled `tiffio.h` applies to that header and is not presented as a license for `tiffmedian.c`; the header is not included here.

The package records attribution and the source pin for provenance. It does not redistribute the upstream source or grant rights in it.

## Ports

| Language | Port |
|---|---|
| C | [`cbench_consumer_tiffmedian.c`](../../../c/cbench_consumer_tiffmedian.c) |
| C3 | [`cbench_consumer_tiffmedian.c3`](../../../c3/c/cbench_consumer_tiffmedian.c3) |
| C++ | [`cbench_consumer_tiffmedian.cpp`](../../../cpp/c/cbench_consumer_tiffmedian.cpp) |
| Elisa | [`cbench_consumer_tiffmedian.elisa`](../../../elisa/c/cbench_consumer_tiffmedian.elisa) |
| Nim | [`cbench_consumer_tiffmedian.nim`](../../../nim/c/cbench_consumer_tiffmedian.nim) |
| Odin | [`cbench_consumer_tiffmedian.odin`](../../../odin/c/cbench_consumer_tiffmedian.odin) |
| Rust | [`cbench_consumer_tiffmedian.rs`](../../../rust/c/cbench_consumer_tiffmedian.rs) |
| V | [`cbench_consumer_tiffmedian.v`](../../../v/c/cbench_consumer_tiffmedian.v) |
| Zig | [`cbench_consumer_tiffmedian.zig`](../../../zig/c/cbench_consumer_tiffmedian.zig) |

Independent oracle: [`cbench_consumer_tiffmedian_oracle.py`](../../cbench_consumer_tiffmedian_oracle.py). Workload: [`workload.json`](workload.json).
