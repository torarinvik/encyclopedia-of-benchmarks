# Intensity based segmentation

The pinned Python routine initializes labels to zero, then visits thresholds in their given order. At threshold index `i`, every pixel strictly greater than that threshold is overwritten with label `i+1`; later matching thresholds therefore replace earlier labels.

## Contract

Input is `[threshold_count, thresholds..., flattened_pixels...]`. Threshold count is 0..4; there are 1..7 pixels; thresholds and grayscale pixel values are bytes. Output packs labels in base 5 with the first pixel in the least significant digit. Invalid inputs return -1.

See [workload](workload.json), [independent oracle](../../intensity_based_segmentation_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/intensity_based_segmentation.py).

| Language | Port |
|---|---|
| C | [`c/i/intensity_based_segmentation.c`](../../../c/i/intensity_based_segmentation.c) |
| C3 | [`c3/i/intensity_based_segmentation.c3`](../../../c3/i/intensity_based_segmentation.c3) |
| C++ | [`c++/i/intensity_based_segmentation.cpp`](../../../c++/i/intensity_based_segmentation.cpp) |
| Elisa | [`elisa/i/intensity_based_segmentation.elisa`](../../../elisa/i/intensity_based_segmentation.elisa) |
| Nim | [`nim/i/intensity_based_segmentation.nim`](../../../nim/i/intensity_based_segmentation.nim) |
| Odin | [`odin/i/intensity_based_segmentation.odin`](../../../odin/i/intensity_based_segmentation.odin) |
| Rust | [`rust/i/intensity_based_segmentation.rs`](../../../rust/i/intensity_based_segmentation.rs) |
| V | [`v/i/intensity_based_segmentation.v`](../../../v/i/intensity_based_segmentation.v) |
| Zig | [`zig/i/intensity_based_segmentation.zig`](../../../zig/i/intensity_based_segmentation.zig) |
