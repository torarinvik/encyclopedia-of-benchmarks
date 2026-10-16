# Flip Augmentation

The pinned Python helper flips each image horizontally (`flip_type = 1`) or vertically (`flip_type = 0`) and reflects the matching normalized bounding-box center. This benchmark measures that deterministic core operation. It uses row-major grayscale bytes and normalized coordinates represented as millionths, so ports need no image library, file access, or floating-point rounding policy.

## Contract

Input is `[width, height, flip_type, box_count, pixels..., boxes...]`. Width and height are 1 to 16, flip type is 0 (vertical) or 1 (horizontal), pixels are bytes, and each box is `[class_id, x_center, y_center, width, height]` with coordinates in `[0, 1000000]`. The input must contain exactly `width * height` pixels and five values per box. Invalid input returns `-1`.

Output starts with the flipped row-major pixel bytes, followed by each box as five little-endian signed i32 values. A horizontal flip changes `x_center` to `1000000 - x_center`; a vertical flip changes `y_center` the same way. The function returns the byte count. Null output or insufficient capacity returns `-2`.

The bounds are 16×16 pixels and 16 boxes, for at most 340 input values and 576 output bytes. [`workload.json`](workload.json) includes both flip directions, empty annotations, invalid inputs, a capacity failure, and maximum dimensions.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/flip_augmentation.c`](../../../c/f/flip_augmentation.c) |
| C3 | [`c3/f/flip_augmentation.c3`](../../../c3/f/flip_augmentation.c3) |
| C++ | [`cpp/f/flip_augmentation.cpp`](../../../cpp/f/flip_augmentation.cpp) |
| Elisa | [`elisa/f/flip_augmentation.elisa`](../../../elisa/f/flip_augmentation.elisa) |
| Nim | [`nim/f/flip_augmentation.nim`](../../../nim/f/flip_augmentation.nim) |
| Odin | [`odin/f/flip_augmentation.odin`](../../../odin/f/flip_augmentation.odin) |
| Rust | [`rust/f/flip_augmentation.rs`](../../../rust/f/flip_augmentation.rs) |
| V | [`v/f/flip_augmentation.v`](../../../v/f/flip_augmentation.v) |
| Zig | [`zig/f/flip_augmentation.zig`](../../../zig/f/flip_augmentation.zig) |

## Pinned source

[TheAlgorithms/Python `flip_augmentation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/flip_augmentation.py)
