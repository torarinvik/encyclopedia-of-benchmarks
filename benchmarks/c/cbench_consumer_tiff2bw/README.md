# cBench `consumer_tiff2bw`: fixed-point RGB-to-gray transform

This package isolates the color-to-gray pixel kernel in the pinned cBench
`consumer_tiff2bw` program. Each interleaved RGB triplet is mapped to one
8-bit grayscale sample using the source's integer percentage weights and
fixed-point shift.

## Bounded contract

The ABI is `cbench_consumer_tiff2bw` with `i64_array_bytes_output` framing:

- Input: `[pixel_count, R0, G0, B0, ...]` in interleaved pixel order.
- `pixel_count` is 1–64 and each channel is an integer in 0–255. The input
  length is exactly `1 + 3*pixel_count`, at most 193 values.
- The source defines each weight with `PCT(x) = (x*255)/100` using integer
  division, yielding `RED=71`, `GREEN=150`, and `BLUE=28`.
- For each pixel, calculate `v = RED*R`, then add `GREEN*G`, then add
  `BLUE*B`, and emit `v >> 8`. The output contains one byte per pixel in
  input order; the function returns `pixel_count`.
- Invalid or null input returns `-1`. A null output pointer or capacity below
  `pixel_count` returns `-2` before writing. Maximum output workspace is 64
  bytes.

The profile implements the interleaved RGB path from `compresscontig` and the
same weighted transform used by `compresssep`. It excludes TIFF decoding,
metadata, palette lookup and conversion, planar buffer handling, compression,
and file I/O. It is distinct from grayscale thresholding, which consumes
already-grayscale samples, and from `sepia`, which applies a color effect
after its grayscale calculation.

## Provenance and rights

Source: [`tiff2bw.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiff2bw/src/tiff2bw.c),
symbols `compresscontig` and `compresssep`, from
`lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
The pinned launcher is
[`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiff2bw/src/info.sh);
it selects the C files in the source directory, adds `-lm`, and supplies no
run options. The input profile selects 8-bit interleaved RGB pixels with the
source's default channel weights.

The source grants permission to use, copy, modify, distribute, and sell the
software and documentation when the complete copyright and permission notice
is retained. It also restricts using Sam Leffler's or Silicon Graphics' names
in advertising without prior written permission. The full notice is retained
in every language port and in [`LICENSE.txt`](LICENSE.txt).

## Workload and oracle

[`workload.json`](workload.json) covers black and white, the three primary
channels, a mixed color, multiple pixels, malformed framing and channel values,
null input, null output, and insufficient capacity. The independent oracle is
[`benchmarks/cbench_consumer_tiff2bw_oracle.py`](../../cbench_consumer_tiff2bw_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`cbench_consumer_tiff2bw.c`](../../../c/cbench_consumer_tiff2bw.c) |
| C3 | [`cbench_consumer_tiff2bw.c3`](../../../c3/cbench_consumer_tiff2bw.c3) |
| C++ | [`cbench_consumer_tiff2bw.cpp`](../../../cpp/cbench_consumer_tiff2bw.cpp) |
| Elisa | [`cbench_consumer_tiff2bw.elisa`](../../../elisa/c/cbench_consumer_tiff2bw.elisa) |
| Nim | [`cbench_consumer_tiff2bw.nim`](../../../nim/c/cbench_consumer_tiff2bw.nim) |
| Odin | [`cbench_consumer_tiff2bw.odin`](../../../odin/c/cbench_consumer_tiff2bw.odin) |
| Rust | [`cbench_consumer_tiff2bw.rs`](../../../rust/c/cbench_consumer_tiff2bw.rs) |
| V | [`cbench_consumer_tiff2bw.v`](../../../v/c/cbench_consumer_tiff2bw.v) |
| Zig | [`cbench_consumer_tiff2bw.zig`](../../../zig/c/cbench_consumer_tiff2bw.zig) |
