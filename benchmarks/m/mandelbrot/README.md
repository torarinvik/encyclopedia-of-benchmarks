# Mandelbrot black-and-white rendering

This benchmark compares the pinned C#, Java, JavaScript, and Python implementations on their shared black-and-white rendering mode. It returns one grayscale byte per pixel instead of a bitmap or RGB triplet; black is 0 and white is 255.

## Contract

The ABI is i64_array_bytes_output. Input is exactly [width, height, center_x_q, center_y_q, figure_width_q, max_step]. Width and height are each 1–16. The view center coordinates use q/16 with q in [-64, 64], and the positive figure width uses q/16 with q in [1, 64]. max_step is 2–64; values below 2 are excluded because the source divides by max_step-1.

Use IEEE-754 binary64 round-to-nearest, ties-to-even after each written arithmetic operation. Preserve the written evaluation order, with fused multiply-add contraction and reassociation disabled. The pixel coordinates follow the source formulas: figure_height = (figure_width / width) * height; figure_x = center_x + ((image_x / width - 0.5) * figure_width); figure_y = center_y + ((image_y / height - 0.5) * figure_height). The source starts each point with a = figure_x and b = figure_y, then repeats a_new = ((a*a) - (b*b)) + figure_x; b = ((2*a)*b) + figure_y; a = a_new, stopping only when ((a*a) + (b*b)) > 4.

The output traversal follows the source loops with image_x outermost and image_y innermost. A pixel is black when the source's normalized distance current_step/(max_step-1) is at least 1, and white otherwise. This preserves the source result when the first escape occurs on the final iteration: that pixel is black because its normalized distance is 1. Malformed framing or out-of-domain values return -1. For valid input, null or undersized output returns -2; success returns width*height. Validation precedes output checks, and errors leave output untouched.

## Pinned sources

- C# Mandelbrot.GetBitmap: https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/Mandelbrot.cs
- Java Mandelbrot.getImage: https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/Mandelbrot.java
- JavaScript getRGBData: https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Mandelbrot.js
- Python get_image/get_distance: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/mandelbrot.py

The image/file wrappers and distance color maps are outside the benchmark; the shared pixel recurrence and black-and-white classification are retained.

## Workload and oracle

- Workload: workload.json
- Oracle: ../../mandelbrot_oracle.py

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/mandelbrot.c`](../../../c/m/mandelbrot.c) |
| C3 | [`c3/m/mandelbrot.c3`](../../../c3/m/mandelbrot.c3) |
| C++ | [`cpp/m/mandelbrot.cpp`](../../../cpp/m/mandelbrot.cpp) |
| Elisa | [`elisa/m/mandelbrot.elisa`](../../../elisa/m/mandelbrot.elisa) |
| Nim | [`nim/m/mandelbrot.nim`](../../../nim/m/mandelbrot.nim) |
| Odin | [`odin/m/mandelbrot.odin`](../../../odin/m/mandelbrot.odin) |
| Rust | [`rust/m/mandelbrot.rs`](../../../rust/m/mandelbrot.rs) |
| V | [`v/m/mandelbrot.v`](../../../v/m/mandelbrot.v) |
| Zig | [`zig/m/mandelbrot.zig`](../../../zig/m/mandelbrot.zig) |

