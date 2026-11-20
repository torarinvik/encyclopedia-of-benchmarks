# Discretized Hough line accumulator

Build a fixed integer Hough accumulator from a small binary image. The profile
uses only integer projections, so every vote and bin selection is exact and
reproducible across the ten language ports.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `hough_line_transform`.
- Input is `[height, width, row-major pixels...]`. Height and width are each
  in `1..8`; the exact valid length is `2 + height*width` (at most 66 signed
  64-bit values). Pixels must be 0 or 1. One extra trailing word is parseable
  but invalid.
- Pixel coordinates use `x=column`, `y=row`, with origin at the upper-left.
  Each foreground pixel votes once for each normal in this fixed order:
  `(1,0)`, `(1,1)`, `(0,1)`, `(-1,1)`. The diagonal normals are deliberately
  unnormalized so all projections remain integer-valued.
- For normal `(nx,ny)`, `rho = nx*x + ny*y`. There are 29 signed rho bins
  `-14..14`; bin `rho` is stored at index `angle_index*29 + rho + 14`. The
  complete accumulator is exactly 116 angle-major bytes. Every count is at
  most 64.
- Invalid or out-of-profile input returns `-1` without writing. A null output
  pointer or capacity below 116 returns `-2` without writing. Valid calls
  return 116 and write all bins, including zero-count bins.
- Exported C ABI: `int64_t hough_line_transform(const int64_t *input,
  size_t length, uint8_t *output, size_t output_capacity)`.

This profile computes only the accumulator. It does not detect edges, select
peaks, estimate continuous angles or distances, draw lines, or recover line
segments. Its explicit finite angle and rho bins are the benchmark's
quantization policy.

## References and workload

The primary reference iterates over foreground pixels and increments four
bins. The independent reference scans every pixel separately for every
angle/rho bin and counts exact projection matches. The workload stores sparse
expected bins as `[byte_index, count]` pairs; omitted bins are zero. The
package-local [`check_inventory.py`](check_inventory.py) validates all ten
ports, contract metadata, sparse fixtures, and agreement between both
references. The primary work is `O(4*height*width + 116)` with a fixed 116-byte
accumulator.

The algorithm is based on Duda and Hart, “Use of the Hough Transformation to
Detect Lines and Curves in Pictures,” *Communications of the ACM*, 15(1), 1972,
[DOI 10.1145/361237.361242](https://doi.org/10.1145/361237.361242). Only the
algorithm idea is used; the small-grid quantization contract and all code,
references, fixtures, and prose are independently authored.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/h/hough_line_transform.c`](../../../c/h/hough_line_transform.c) |
| C3 | [`c3/h/hough_line_transform.c3`](../../../c3/h/hough_line_transform.c3) |
| C++ | [`cpp/h/hough_line_transform.cpp`](../../../cpp/h/hough_line_transform.cpp) |
| Elisa | [`elisa/h/hough_line_transform.elisa`](../../../elisa/h/hough_line_transform.elisa) |
| Mojo | [`mojo/h/hough_line_transform.mojo`](../../../mojo/h/hough_line_transform.mojo) |
| Nim | [`nim/h/hough_line_transform.nim`](../../../nim/h/hough_line_transform.nim) |
| Odin | [`odin/h/hough_line_transform.odin`](../../../odin/h/hough_line_transform.odin) |
| Rust | [`rust/h/hough_line_transform.rs`](../../../rust/h/hough_line_transform.rs) |
| V | [`v/h/hough_line_transform.v`](../../../v/h/hough_line_transform.v) |
| Zig | [`zig/h/hough_line_transform.zig`](../../../zig/h/hough_line_transform.zig) |
