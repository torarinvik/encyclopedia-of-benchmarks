# Erosion operation

This benchmark follows the pinned Python `erosion` routine with its demonstrated 3×3 cross structuring element. Inputs are binary grids, bounded to 1–6 rows and 1–6 columns. The image is zero-padded; an output pixel is one exactly when the source pixel and its four orthogonal neighbors are all one. Pixels outside the image count as zero.

The ABI input is `[height, width, row-major binary pixels...]`. The output is a nonnegative integer bitfield in row-major order: bit `row * width + column` is one for each eroded pixel. Invalid inputs return `-1`. The 36-bit maximum output fits in a signed 64-bit scalar.

The workload covers the cross footprint, corners, boundary padding, degenerate dimensions, and invalid shapes and pixels. The independent runtime oracle is [`erosion_operation_oracle.py`](../../erosion_operation_oracle.py).

Pinned source: [TheAlgorithms/Python `erosion_operation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/morphological_operations/erosion_operation.py).

Ports:

- C: [`c/e/erosion_operation.c`](../../../c/e/erosion_operation.c)
- C3: [`c3/e/erosion_operation.c3`](../../../c3/e/erosion_operation.c3)
- C++: [`cpp/e/erosion_operation.cpp`](../../../cpp/e/erosion_operation.cpp)
- Elisa: [`elisa/e/erosion_operation.elisa`](../../../elisa/e/erosion_operation.elisa)
- Nim: [`nim/e/erosion_operation.nim`](../../../nim/e/erosion_operation.nim)
- Odin: [`odin/e/erosion_operation.odin`](../../../odin/e/erosion_operation.odin)
- Rust: [`rust/e/erosion_operation.rs`](../../../rust/e/erosion_operation.rs)
- V: [`v/e/erosion_operation.v`](../../../v/e/erosion_operation.v)
- Zig: [`zig/e/erosion_operation.zig`](../../../zig/e/erosion_operation.zig)
