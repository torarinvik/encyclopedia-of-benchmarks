# Embench picojpeg bounded block decoder

This clean-room package profiles a deliberately restricted, valid JPEG baseline grayscale block through the same major decoder stages used by Embench-IoT's picojpeg: marker/header recognition, quantization-table loading, canonical Huffman decoding of a DC difference and one AC coefficient, dequantization, and 8×8 inverse DCT reconstruction. It does not copy picojpeg implementation code.

## Contract

Export `picojpeg` with the `i64_array_bytes_output` ABI. Input is exactly 139 unsigned byte values encoding a single 8×8 baseline grayscale JPEG block with this fixed marker sequence: SOI, one 8-bit DQT, one 8-bit one-component SOF0, one DHT segment with one DC and two AC symbols, one single-component SOS, two scan bytes, and EOI. The input permits only quantization entries 0 and 1 to vary; all other entries must be 1. The DC Huffman table has its sole length-1 symbol category 4. The AC table maps length-1 code `0` to run 0/size 4, and length-2 code `10` to EOB. Entropy data encodes one signed category-4 DC difference, one signed category-4 AC coefficient at zigzag position 1, EOB, then four one-bit pad bits. The accepted signed coefficient values are `-15..-8` or `8..15`.

The four-bit JPEG category amplitudes decode as `raw` for `raw >= 8`, otherwise `raw - 15`; thus the coefficient values are `-15..-8` and `8..15`. The coefficients are dequantized using quantization entries zero and one. The profile uses a deterministic Q16 approximation of the standard 8×8 IDCT basis for the single horizontal AC frequency. For column `x`, the basis constants are `[11363, 9633, 6436, 2260, -2260, -6436, -9633, -11363] / 65536`; each output pixel is `clamp(floor(128 + DC*Q0/8 + AC*Q1*basis[x] + 0.5), 0, 255)`. This restricted coefficient set produces rows that repeat across all eight rows. Output is 64 row-major grayscale bytes.

Malformed or unsupported JPEG frames return `-1` before checking the output buffer. A null output or capacity below 64 returns `-2` without writes; success returns 64. The input bound is 139 values and output bound is 64 bytes.

This is a bounded decoder profile, not a general JPEG implementation: it excludes color, subsampling, multi-block images, arbitrary Huffman tables, progressive scans, restart intervals, and the original benchmark’s repeated image workload/harness. It is distinct from image convolution and other image-processing packages.

## Provenance and rights

- Repository: [embench/embench-iot](https://github.com/embench/embench-iot)
- Commit: `09c2ed8c3b7008c95d08b038de4a3f6dc103ed70`
- Decoder source: [`src/picojpeg/libpicojpeg.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/picojpeg/libpicojpeg.c)
- Benchmark harness: [`src/picojpeg/picojpeg_test.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/picojpeg/picojpeg_test.c)
- The Embench wrapper/library files declare GPL-3.0-or-later and attribute the original picojpeg v1.1 algorithm to Rich Geldreich as public domain; the integrated change history also credits Chris Phoenix. The GPL license text and source attribution are bundled in [`LICENSE.txt`](LICENSE.txt) and [`NOTICE.txt`](NOTICE.txt). This package is independently implemented from the bounded JPEG syntax and mathematical transform contract.

[`workload.json`](workload.json) records source metadata and fixtures. [`picojpeg_oracle.py`](../../picojpeg_oracle.py) independently checks the restricted marker, Huffman, coefficient, and transform contract.

| Language | Port |
|---|---|
| C | [`c/p/picojpeg.c`](../../../c/p/picojpeg.c) |
| C3 | [`c3/p/picojpeg.c3`](../../../c3/p/picojpeg.c3) |
| C++ | [`cpp/p/picojpeg.cpp`](../../../cpp/p/picojpeg.cpp) |
| Elisa | [`elisa/p/picojpeg.elisa`](../../../elisa/p/picojpeg.elisa) |
| Nim | [`nim/p/picojpeg.nim`](../../../nim/p/picojpeg.nim) |
| Odin | [`odin/p/picojpeg.odin`](../../../odin/p/picojpeg.odin) |
| Rust | [`rust/p/picojpeg.rs`](../../../rust/p/picojpeg.rs) |
| V | [`v/p/picojpeg.v`](../../../v/p/picojpeg.v) |
| Zig | [`zig/p/picojpeg.zig`](../../../zig/p/picojpeg.zig) |

No runtime or compiler verification is claimed.
