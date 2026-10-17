# Piecewise linear contrast stretch

This benchmark isolates the first pixel mapping in the pinned
TheAlgorithms/Jupyter notebook
[`piecewise_linear_transform.ipynb`](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/Piecewise/piecewise_linear_transform.ipynb).
It applies the notebook's contrast-stretch `pixel_value` function with its
first cell's fixed parameters `r1=100`, `s1=50`, `r2=180`, and `s2=200`.
The later gray-level-slicing cell, image loading, and plotting are separate
operations and are excluded.

## Contract

- ABI: `i64_array_bytes_output`. Input is a nonempty array of grayscale pixel
  values, each in `[0, 255]`; the array length is the pixel count, bounded to
  `[1, 256]`.
- For each pixel `x`, evaluate the pinned branches in order: when `x <= 100`,
  `(50 / 100) * x`; otherwise when `x <= 180`,
  `((200 - 50) / (180 - 100)) * (x - 100) + 50`; otherwise,
  `((255 - 200) / (255 - 180)) * (x - 180) + 200`. Preserve binary64
  expression order, then truncate toward zero when converting to an unsigned
  byte, matching NumPy's `astype(np.uint8)` on this bounded nonnegative range.
- Return one output byte per input pixel in input order. Success returns the
  output byte length. Invalid input returns `-1`; a null output pointer or
  capacity below the pixel count returns `-2` without writing.
- Maximum input length is 256 values and maximum output length is 256 bytes.

The source notebook uses `cv2.imread(..., 0)` to produce grayscale uint8
pixels, vectorizes `pixel_value`, and casts the result to uint8. The benchmark
supplies those pixel values directly so it can cover all grayscale levels
without depending on an image file or plotting library.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/p/piecewise_linear_transform.c`](../../../c/p/piecewise_linear_transform.c) |
| C3 | [`c3/p/piecewise_linear_transform.c3`](../../../c3/p/piecewise_linear_transform.c3) |
| C++ | [`cpp/p/piecewise_linear_transform.cpp`](../../../cpp/p/piecewise_linear_transform.cpp) |
| Elisa | [`elisa/p/piecewise_linear_transform.elisa`](../../../elisa/p/piecewise_linear_transform.elisa) |
| Nim | [`nim/p/piecewise_linear_transform.nim`](../../../nim/p/piecewise_linear_transform.nim) |
| Odin | [`odin/p/piecewise_linear_transform.odin`](../../../odin/p/piecewise_linear_transform.odin) |
| Rust | [`rust/p/piecewise_linear_transform.rs`](../../../rust/p/piecewise_linear_transform.rs) |
| V | [`v/p/piecewise_linear_transform.v`](../../../v/p/piecewise_linear_transform.v) |
| Zig | [`zig/p/piecewise_linear_transform.zig`](../../../zig/p/piecewise_linear_transform.zig) |

## Workload and oracle

[`workload.json`](workload.json) covers all 256 pixel levels, every piecewise
boundary, malformed and out-of-range values, and null or undersized output
buffers. The independent [oracle](../../piecewise_linear_transform_oracle.py)
evaluates the three source expressions and serializes the truncated bytes.

## Pinned source

[TheAlgorithms/Jupyter notebook at its pinned revision](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/Piecewise/piecewise_linear_transform.ipynb)
contains the isolated pixel transform in its first mapping cell.
