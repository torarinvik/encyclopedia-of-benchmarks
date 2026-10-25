# IJG YCbCr-to-RGB table conversion

This package isolates the 8-bit `ycc_rgb_convert` pixel kernel selected by the pinned MiBench `consumer-jpeg` decoder path. It is a color-space conversion only; JPEG marker parsing, Huffman decoding, IDCT, chroma upsampling, scanline management, and image I/O are excluded. The existing `picojpeg` profile is restricted to grayscale input and does not cover this color conversion. The separate TIFF RGB-to-grayscale benchmark also has a different operation and coefficients.

## Contract

ABI: `i64_array_bytes_output`; exported symbol: `mibench_jpeg_ycbcr_to_rgb`.

Input is `[pixel_count, Y0, Cb0, Cr0, ...]`, with `1 <= pixel_count <= 16` and each 8-bit sample in `0..255`. Output is row-major RGB triples, exactly `3*pixel_count` bytes. For each pixel the IJG code uses centered chroma `cb=Cb-128`, `cr=Cr-128`, scale `2^16`, and `FIX(x)=trunc(x*65536+0.5)`. The red/blue table terms are arithmetic-shifted after adding 32768; green combines both scaled terms and one 32768 bias before a single arithmetic right shift. The resulting channels pass through IJG's 8-bit range-limit table, equivalent on this bounded profile to clamping to `0..255`. Validation precedes output-capacity checks; malformed input returns `-1`, and null/short output returns `-2` without writes.

The contract preserves the source's fixed-point constants and operation order, including the distinct rounding path for green. Its source profile is 8-bit samples with center 128; higher sample precisions and YCCK/CMYK modes are excluded.

## Provenance and rights

- Repository and pin: [`lac-dcc/Benchmarks@5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38).
- Launcher: [`MiBench/consumer-jpeg/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-jpeg/info.sh), which selects `-dct int -ppm` and compiles `jdcolor.c`.
- Kernel: [`MiBench/consumer-jpeg/jdcolor.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-jpeg/jdcolor.c), copyright 1991–1996 Thomas G. Lane, especially `build_ycc_rgb_table` and `ycc_rgb_convert`.
- The pinned IJG README permits use, copying, modification, and distribution subject to its conditions and notice. This package is an independently written implementation; the applicable IJG notice is reproduced in [`LICENSE.txt`](LICENSE.txt).

The independent oracle is [`mibench_jpeg_ycbcr_to_rgb_oracle.py`](../../mibench_jpeg_ycbcr_to_rgb_oracle.py). Fixtures are recorded in [`workload.json`](workload.json). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/m/mibench_jpeg_ycbcr_to_rgb.c`](../../../c/m/mibench_jpeg_ycbcr_to_rgb.c)
- C3: [`c3/m/mibench_jpeg_ycbcr_to_rgb.c3`](../../../c3/m/mibench_jpeg_ycbcr_to_rgb.c3)
- C++: [`cpp/m/mibench_jpeg_ycbcr_to_rgb.cpp`](../../../cpp/m/mibench_jpeg_ycbcr_to_rgb.cpp)
- Elisa: [`elisa/m/mibench_jpeg_ycbcr_to_rgb.elisa`](../../../elisa/m/mibench_jpeg_ycbcr_to_rgb.elisa)
- Nim: [`nim/m/mibench_jpeg_ycbcr_to_rgb.nim`](../../../nim/m/mibench_jpeg_ycbcr_to_rgb.nim)
- Odin: [`odin/m/mibench_jpeg_ycbcr_to_rgb.odin`](../../../odin/m/mibench_jpeg_ycbcr_to_rgb.odin)
- Rust: [`rust/m/mibench_jpeg_ycbcr_to_rgb.rs`](../../../rust/m/mibench_jpeg_ycbcr_to_rgb.rs)
- V: [`v/mibench_jpeg_ycbcr_to_rgb.v`](../../../v/mibench_jpeg_ycbcr_to_rgb.v)
- Zig: [`zig/mibench_jpeg_ycbcr_to_rgb.zig`](../../../zig/mibench_jpeg_ycbcr_to_rgb.zig)
