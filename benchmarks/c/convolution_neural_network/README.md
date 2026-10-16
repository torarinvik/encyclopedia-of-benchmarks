# Convolutional Neural Network Inference

This benchmark isolates the deterministic `predict` path from the pinned Python CNN class. Each call supplies the image, convolution kernels, hidden/output weights, and thresholds, so initialization randomness and model-file loading do not affect the result.

## Contract

- The `i64_array_bytes_output` input begins with `[image_side, kernel_side, stride, filter_count, pooling_side, hidden_units, output_units]`, followed by row-major image pixels, each convolution kernel, convolution thresholds, hidden weights, output weights, hidden thresholds, and output thresholds.
- All values after the seven dimensions are signed integers in millionths. Image pixels are in `[0, 1]`; weights are in `[-0.5, 0.5]`; thresholds are in `[-1, 1]`.
- Image sides are 2–8, kernels 1–4, strides 1–4, filters 1–3, pooling sides 1–2, hidden units 1–8, and outputs 1–4. The valid convolution side must divide evenly into non-overlapping average-pooling windows.
- Convolution is valid (no padding), uses the given stride, applies sigmoid after subtracting each filter threshold, then average-pools. Feature maps flatten in filter, row, column order. Dense hidden and output layers also use sigmoid after threshold subtraction.
- The output contains one little-endian IEEE-754 binary64 value per output unit, rounded to three decimal places using ties-to-even. Invalid input returns `-1`; insufficient output capacity returns `-2`.

## Source semantics

The pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/convolution_neural_network.py) includes a randomized constructor, training/backpropagation, serialization, plotting, and an image demo. The benchmark uses its explicit-parameter inference path: valid convolution, sigmoid activation, average pooling, flattening, two dense sigmoid layers, and three-decimal output. Training and model-loading behavior are outside this contract. The upstream Python repository is MIT licensed.

## Workload

[`workload.json`](workload.json) includes one-, two-, and three-filter models, stride and pooling behavior, zero pixels, rounded probabilities, invalid shapes and values, malformed parameter counts, and insufficient output capacity. The generic byte-output runner compares the float-vector output with [`convolution_neural_network_oracle.py`](../../convolution_neural_network_oracle.py).

All nine implementations build and pass the 12 workload cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/convolution_neural_network.c`](../../../c/c/convolution_neural_network.c) |
| C3 | [`c3/c/convolution_neural_network.c3`](../../../c3/c/convolution_neural_network.c3) |
| C++ | [`cpp/c/convolution_neural_network.cpp`](../../../cpp/c/convolution_neural_network.cpp) |
| Elisa | [`elisa/c/convolution_neural_network.elisa`](../../../elisa/c/convolution_neural_network.elisa) |
| Nim | [`nim/c/convolution_neural_network.nim`](../../../nim/c/convolution_neural_network.nim) |
| Odin | [`odin/c/convolution_neural_network.odin`](../../../odin/c/convolution_neural_network.odin) |
| Rust | [`rust/c/convolution_neural_network.rs`](../../../rust/c/convolution_neural_network.rs) |
| V | [`v/c/convolution_neural_network.v`](../../../v/c/convolution_neural_network.v) |
| Zig | [`zig/c/convolution_neural_network.zig`](../../../zig/c/convolution_neural_network.zig) |

