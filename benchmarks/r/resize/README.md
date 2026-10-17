# Nearest-neighbor image resize

This package ports the pinned Python `NearestNeighbour` kernel. It maps each destination pixel to one source pixel using the source/destination width and height ratios, then copies all three channel bytes unchanged. The OpenCV image-loading and display calls in the source's demo are outside the benchmark.

## Contract

The `i64_array_bytes_output` ABI receives `[src_width, src_height, dst_width, dst_height, source_pixels...]`. Source pixels are unsigned 8-bit channel values flattened in row-major height/width/channel order. Each dimension is in `1..=32`, each channel is in `0..=255`, and the packed length is exactly `4 + 3*src_width*src_height` (maximum 3,076 signed 64-bit values; parser cap 3,077 admits one trailing value for malformed-input coverage).

For each destination row `y` and column `x`, compute the binary64 ratios `ratio_x = src_width/dst_width` and `ratio_y = src_height/dst_height` once. Select `src_x = int(ratio_x*x)` and `src_y = int(ratio_y*y)`, truncating toward zero, and copy that source pixel's three channel values unchanged. The output is raw row-major destination channel bytes without a header, exactly `3*dst_width*dst_height` bytes. Maximum output and workspace are 3,072 bytes. RGB is the contract's channel label; the source kernel copies channel positions without color conversion.

Malformed shape, dimensions, or channel values return `-1`. For valid input, a null output pointer or insufficient capacity returns `-2` without writes. Success returns the number of bytes written. Source dimensions and destination dimensions must be positive; zero dimensions fail in the source's ratio/index operations and are excluded by this bounded contract.

Pinned source: [TheAlgorithms/Python `resize.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/resize/resize.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. See [workload](workload.json) and [oracle](../../resize_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/r/resize.c |
| C3 | ../../../c3/r/resize.c3 |
| C++ | ../../../cpp/r/resize.cpp |
| Elisa | ../../../elisa/r/resize.elisa |
| Nim | ../../../nim/r/resize.nim |
| Odin | ../../../odin/r/resize.odin |
| Rust | ../../../rust/r/resize.rs |
| V | ../../../v/r/resize.v |
| Zig | ../../../zig/r/resize.zig |
