# Simple Neural Network

This package benchmarks the pinned [Python `forward_propagation` source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/simple_neural_network.py) using deterministic initialization. The input supplies the odd initial weight in place of the source random draw. For each propagation, compute `layer = sigmoid(0.02 * weight)`, `delta = (expected/100 - layer) * layer * (1-layer)`, then update `weight += 0.02 * delta`. Return the last forward-pass layer multiplied by 100; that result is computed before the final weight update.

The `i64_array_float64` ABI packs `[expected, initial_weight, propagation_count]`. Expected is 0..100, initial weight is an odd integer in 1..199, and propagation count is 1..65,536. The nonzero count preserves the source’s defined return behavior. Invalid input returns `-1e300`; output uses absolute and relative tolerance `1e-12`. Runtime is O(propagation_count); auxiliary space is O(1).

## Language ports

- C: [`c/s/simple_neural_network.c`](../../../c/s/simple_neural_network.c)
- C3: [`c3/s/simple_neural_network.c3`](../../../c3/s/simple_neural_network.c3)
- CPP: [`cpp/s/simple_neural_network.cpp`](../../../cpp/s/simple_neural_network.cpp)
- ELISA: [`elisa/s/simple_neural_network.elisa`](../../../elisa/s/simple_neural_network.elisa)
- NIM: [`nim/s/simple_neural_network.nim`](../../../nim/s/simple_neural_network.nim)
- ODIN: [`odin/s/simple_neural_network.odin`](../../../odin/s/simple_neural_network.odin)
- RUST: [`rust/s/simple_neural_network.rs`](../../../rust/s/simple_neural_network.rs)
- V: [`v/s/simple_neural_network.v`](../../../v/s/simple_neural_network.v)
- ZIG: [`zig/s/simple_neural_network.zig`](../../../zig/s/simple_neural_network.zig)
