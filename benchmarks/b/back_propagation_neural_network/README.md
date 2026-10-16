# Back Propagation Neural Network

This benchmark extracts the deterministic update performed by the pinned Python `DenseLayer` implementation. It uses a scalar 1→1→1 network, fixed supplied weights, one sample, and one update. This keeps the train-step arithmetic comparable while avoiding the example's random initialization, training-data generation, and plotting.

## Contract

- Input is `[input_q, target_q, hidden_weight_q, hidden_bias_q, output_weight_q, output_bias_q, learning_rate_q]`, with all values scaled by 1,000,000. The input and target are in `[-1, 1]`; weights and biases are in `[-2, 2]`; learning rate is from `0.000001` through `0.3`.
- Both dense layers use sigmoid. The pinned source computes each net input as `weight * input - bias`, uses squared error and its `2 * (prediction - target)` derivative, then updates weights and biases in reverse layer order.
- Output is `[loss_q, hidden_activation_q, prediction_q, updated_hidden_weight_q, updated_hidden_bias_q, updated_output_weight_q, updated_output_bias_q]`, encoded as seven little-endian signed i64 values. Floating results are rounded to the nearest micro-unit, with ties away from zero.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing; success returns 56.
- Implementations use portable scalar floating-point and standard exponential functions; no CPU-specific instructions are used.

The verifier covers source equations, saturated and near-linear sigmoid inputs, signed updates, invalid inputs, output capacity, and deterministic random cases.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm back_propagation_neural_network --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/back_propagation_neural_network/rust/build.json
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/back_propagation_neural_network.c`](../../../c/b/back_propagation_neural_network.c) |
| C3 | [`c3/b/back_propagation_neural_network.c3`](../../../c3/b/back_propagation_neural_network.c3) |
| C++ | [`cpp/b/back_propagation_neural_network.cpp`](../../../cpp/b/back_propagation_neural_network.cpp) |
| Elisa | [`elisa/b/back_propagation_neural_network.elisa`](../../../elisa/b/back_propagation_neural_network.elisa) |
| Nim | [`nim/b/back_propagation_neural_network.nim`](../../../nim/b/back_propagation_neural_network.nim) |
| Odin | [`odin/b/back_propagation_neural_network.odin`](../../../odin/b/back_propagation_neural_network.odin) |
| Rust | [`rust/b/back_propagation_neural_network.rs`](../../../rust/b/back_propagation_neural_network.rs) |
| V | [`v/b/back_propagation_neural_network.v`](../../../v/b/back_propagation_neural_network.v) |
| Zig | [`zig/b/back_propagation_neural_network.zig`](../../../zig/b/back_propagation_neural_network.zig) |

## Pinned source

- TheAlgorithms/Python [`back_propagation_neural_network.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/back_propagation_neural_network.py)
