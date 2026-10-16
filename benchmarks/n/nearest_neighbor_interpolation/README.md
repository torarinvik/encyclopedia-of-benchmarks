# Nearest-neighbor interpolation

This benchmark extracts the nearest-neighbor sampling loop from the pinned MATLAB `zoomimg.m` demo. The source fixes the scale at 1.5, loads `lena_color.bmp`, and displays figures; this portable benchmark supplies a bounded grayscale matrix and measures only the resampling operation.

## Contract

- Pack signed 64-bit integers as `[rows, columns, grayscale pixels...]`, with pixels in row-major order and exactly `2 + rows*columns` values.
- Rows and columns are in `1..=16`; grayscale values are in `0..=255`.
- The zoom factor is fixed at 1.5. Output dimensions are `floor(1.5*rows)` by `floor(1.5*columns)`, matching MATLAB's `1:zoom*dimension` loop bounds.
- For each one-based output coordinate `i`, sample the one-based source coordinate `round(i/1.5)`, clamped to at least 1 as in the source. The bounded output grid maps entirely inside the source image. Implementations use an exact integer form of this coordinate mapping.
- Return row-major output pixels as raw bytes, with one byte per grayscale value. A successful call returns the number of bytes written. Malformed input returns `-1`; insufficient output capacity or a null output buffer returns `-2`.

The original file is a demo rather than a reusable function: image loading, the hard-coded color image, and plotting are outside this benchmark. The grayscale contract makes the intended two-dimensional spatial interpolation explicit and avoids comparing language-specific image libraries or color-channel layouts.

## Source and verification

- MATLAB [`zoomimg.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/ImageProcessing/Nearest%20Neighbhor%20Interpolation/zoomimg.m), commit `e150b77ad256de46c1ce3815c3d7945ac4fc28dc`, under the repository's [MIT license](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/LICENSE).

[`workload.json`](workload.json) covers 1×1, 1×2, 2×2, odd and maximum dimensions, grayscale boundaries, malformed input, and insufficient capacity. Verify the nine implementations against the independent oracle and workload:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm nearest_neighbor_interpolation
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/nearest_neighbor_interpolation.c`](../../../c/n/nearest_neighbor_interpolation.c) |
| C3 | [`c3/n/nearest_neighbor_interpolation.c3`](../../../c3/n/nearest_neighbor_interpolation.c3) |
| C++ | [`cpp/n/nearest_neighbor_interpolation.cpp`](../../../cpp/n/nearest_neighbor_interpolation.cpp) |
| Elisa | [`elisa/n/nearest_neighbor_interpolation.elisa`](../../../elisa/n/nearest_neighbor_interpolation.elisa) |
| Nim | [`nim/n/nearest_neighbor_interpolation.nim`](../../../nim/n/nearest_neighbor_interpolation.nim) |
| Odin | [`odin/n/nearest_neighbor_interpolation.odin`](../../../odin/n/nearest_neighbor_interpolation.odin) |
| Rust | [`rust/n/nearest_neighbor_interpolation.rs`](../../../rust/n/nearest_neighbor_interpolation.rs) |
| V | [`v/n/nearest_neighbor_interpolation.v`](../../../v/n/nearest_neighbor_interpolation.v) |
| Zig | [`zig/n/nearest_neighbor_interpolation.zig`](../../../zig/n/nearest_neighbor_interpolation.zig) |
