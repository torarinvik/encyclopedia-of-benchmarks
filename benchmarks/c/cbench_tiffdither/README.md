# cBench TIFF Floyd–Steinberg dithering

This benchmark ports the `fsdither` grayscale core from the pinned cBench
`consumer_tiffdither` workload. It converts a small 8-bit grayscale image into
a one-bit image using raster-order Floyd–Steinberg error diffusion.

## Contract

The `i64_array_bytes_output` input is `[width, height, threshold, pixels...]`,
with one grayscale byte per pixel in row-major order. Width is 1–32, height is
2–16, threshold and pixels are 0–255, and the input has exactly
`3 + width * height` values. Invalid input returns `-1`.

Each pixel is clamped to 0–255, compared strictly against the threshold, and
quantized to black or white. The signed quantization error is diffused in the
source order using C-style integer division toward zero: 7/16 east, 3/16
southwest, 5/16 south, and 1/16 southeast. Output rows are packed left to
right, most-significant bit first; unused low bits in the final byte are zero.
The pinned routine writes rows `0` through `height-2`: its scanline loop reads
the final input row, but the last-line flag suppresses downward diffusion and
the row is not emitted, so it does not affect the result. The output length is
`ceil(width / 8) * (height - 1)`. A null output pointer or insufficient output
capacity returns `-2` without writing.

The benchmark omits TIFF parsing, metadata, and file I/O while preserving the
active launcher's grayscale `fsdither` operation. The threshold input exposes
the source's `-t` option; its default is 128. Unlike the existing
[`burkes_dithering`](../../b/burkes_dithering/README.md) package, this uses the
Floyd–Steinberg four-neighbor kernel, accepts grayscale pixels, and returns
packed output bytes.

## Provenance and rights

Source: [`cBench/consumer_tiffdither/src/tiffdither.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiffdither/src/tiffdither.c),
symbol `fsdither`, at commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38).
The pinned launcher is `cBench/consumer_tiffdither/src/info.sh`; it compiles
the C sources with `-lm` and supplies no extra run options. The upstream notice
permits use, modification, distribution, and sale if the complete notice is
retained, and restricts using Sam Leffler's or Silicon Graphics' names in
advertising without prior written permission. The full notice is retained in
every port and reproduced below.

## Workload

[`workload.json`](workload.json) covers strict thresholding, horizontal and
vertical error propagation, negative-error division, byte packing, the
source's unused final input row, malformed dimensions and pixels, and
output-capacity errors. The independent oracle is
[`cbench_tiffdither_oracle.py`](../../cbench_tiffdither_oracle.py).

## Upstream copyright and permission notice

```text
Copyright (c) 1988-1997 Sam Leffler
Copyright (c) 1991-1997 Silicon Graphics, Inc.

Permission to use, copy, modify, distribute, and sell this software and
its documentation for any purpose is hereby granted without fee, provided
that (i) the above copyright notices and this permission notice appear in
all copies of the software and related documentation, and (ii) the names of
Sam Leffler and Silicon Graphics may not be used in any advertising or
publicity relating to the software without the specific, prior written
permission of Sam Leffler and Silicon Graphics.

THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.
```

| Language | Port |
| --- | --- |
| C | [`c/cbench_tiffdither.c`](../../../c/c/cbench_tiffdither.c) |
| C3 | [`c3/cbench_tiffdither.c3`](../../../c3/c/cbench_tiffdither.c3) |
| C++ | [`cpp/cbench_tiffdither.cpp`](../../../cpp/c/cbench_tiffdither.cpp) |
| Elisa | [`elisa/cbench_tiffdither.elisa`](../../../elisa/c/cbench_tiffdither.elisa) |
| Nim | [`nim/cbench_tiffdither.nim`](../../../nim/c/cbench_tiffdither.nim) |
| Odin | [`odin/cbench_tiffdither.odin`](../../../odin/c/cbench_tiffdither.odin) |
| Rust | [`rust/cbench_tiffdither.rs`](../../../rust/c/cbench_tiffdither.rs) |
| V | [`v/cbench_tiffdither.v`](../../../v/c/cbench_tiffdither.v) |
| Zig | [`zig/cbench_tiffdither.zig`](../../../zig/c/cbench_tiffdither.zig) |
