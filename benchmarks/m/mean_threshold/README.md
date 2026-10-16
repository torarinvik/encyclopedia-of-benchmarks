# Mean threshold

This benchmark preserves the pinned Python image routine on bounded grayscale images. It computes the integer floor of the mean pixel value, then maps each pixel strictly greater than that threshold to 255 and every other pixel to 0.

## Contract

Input is a signed 64-bit array [side, pixel_0, ..., pixel_(side*side-1)]. Pixels are row-major grayscale values in 0..255; side is in 1..32, and the input must contain exactly side*side pixels. The output is a row-major byte string containing only 0 or 255. A malformed input returns -1; an output buffer that is too small or null returns -2. The maximum output is 1,024 bytes.

The pinned function unpacks image.size into height, width, then indexes the pixel matrix using both dimensions in reversed roles. Restricting the benchmark to nonempty square images makes those accesses valid and covers the routine's thresholding behavior. The transformation uses floor division and a strict pixel-greater-than-mean comparison, so pixels equal to the mean become 0. The Python routine mutates and returns its image; the benchmark returns the resulting pixel bytes.

## Pinned source

TheAlgorithms/Python mean_threshold.py at commit e1a2a8b016001309a73d5fec4818c35cca139795:
https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/mean_threshold.py

## Build and record

After the shared bytes-output runner registers this algorithm:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm mean_threshold --language c
    python3 benchmarks/run_i64_array_bytes_output.py --algorithm mean_threshold

## Language ports

| Language | Source |
| --- | --- |
| C | c/m/mean_threshold.c |
| C3 | c3/m/mean_threshold.c3 |
| C++ | cpp/m/mean_threshold.cpp |
| Elisa | elisa/m/mean_threshold.elisa |
| Nim | nim/m/mean_threshold.nim |
| Odin | odin/m/mean_threshold.odin |
| Rust | rust/m/mean_threshold.rs |
| V | v/m/mean_threshold.v |
| Zig | zig/m/mean_threshold.zig |

