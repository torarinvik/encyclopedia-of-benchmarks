# Burkes dithering

Convert a small square BGR image to black-and-white pixels with Burkes error diffusion.

## Contract

The `i64_array_scalar` input is `[side, threshold, B, G, R, ...]`, with one BGR triplet per pixel in row-major order. Images are square with side 1 through 7, channel values are bytes, and threshold is 1 through 254. Malformed input returns `-1`.

The benchmark uses an exact integer grayscale conversion, `floor((114B + 587G + 299R) / 1000)`, and propagates integer error with truncation toward zero at the source's 8/32, 4/32, 2/32, 4/32, 8/32, 4/32, 2/32 weights. A pixel is black when `threshold > adjusted_gray`; otherwise it is white. The signed result sets bit `y * side + x` for each white pixel. Limiting the source-shaped image to squares avoids its width/height-reversed output allocation.

The Python source performs grayscale conversion in binary64 before truncating. Exact integer weights remove compiler-dependent floating-point boundary artifacts from the portable contract; the dither scan and error diffusion order are retained.

## Source

- Python [`burkes.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/dithering/burkes.py)

## Workload and verification

[`workload.json`](workload.json) covers black and white pixels, threshold edges, color-channel weighting, error propagation, malformed dimensions, and invalid channels. The verifier exhaustively checks small grayscale patterns and adds deterministic color images against an independent integer oracle.

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithm burkes_dithering --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm burkes_dithering --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/burkes_dithering/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/burkes_dithering.c`](../../../c/b/burkes_dithering.c) |
| C3 | [`c3/b/burkes_dithering.c3`](../../../c3/b/burkes_dithering.c3) |
| C++ | [`cpp/b/burkes_dithering.cpp`](../../../cpp/b/burkes_dithering.cpp) |
| Elisa | [`elisa/b/burkes_dithering.elisa`](../../../elisa/b/burkes_dithering.elisa) |
| Nim | [`nim/b/burkes_dithering.nim`](../../../nim/b/burkes_dithering.nim) |
| Odin | [`odin/b/burkes_dithering.odin`](../../../odin/b/burkes_dithering.odin) |
| Rust | [`rust/b/burkes_dithering.rs`](../../../rust/b/burkes_dithering.rs) |
| V | [`v/b/burkes_dithering.v`](../../../v/b/burkes_dithering.v) |
| Zig | [`zig/b/burkes_dithering.zig`](../../../zig/b/burkes_dithering.zig) |
