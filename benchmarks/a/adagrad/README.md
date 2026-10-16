# AdaGrad scalar update trace

## Contract

The pinned Python source is a stateful optimizer. For each parameter group, it starts a zero accumulator on the first update, adds each gradient squared elementwise, then returns `params - learning_rate / (sqrt(accumulator) + epsilon) * gradient`. The implementation places epsilon outside the square root; this follows the executable source even though its class docstring shows epsilon inside it.

This benchmark bounds the vector API to one scalar parameter per update and up to 16 parameter IDs. A call contains a sequence of update records, so the accumulator persists for repeated IDs and remains independent between IDs. The packed signed 64-bit input is `[step_count, learning_rate_scaled, epsilon_scaled, (parameter_id, parameter_scaled, gradient_scaled)...]`. Parameters, gradients, learning rate, and epsilon are encoded at scale 1,000,000,000. The step count is 1 through 256; IDs are 0 through 15; learning rate is in `[1e-9, 1]`; epsilon is in `[1e-9, 0.01]`; parameters are in `[-1e6, 1e6]`; gradients are in `[-1000, 1000]`. Malformed or out-of-range input returns `-1`.

The function returns the number of updates and writes one signed 64-bit fixed-point updated parameter per step, in input order, little-endian, with output scale 1,000,000. Each update uses binary64 arithmetic and keeps its unquantized internal accumulator; only the returned parameter is quantized. A too-small output buffer returns `-2` without writing output.

## Workload and ABI

[`workload.json`](workload.json) covers repeated updates to one ID, interleaved IDs, zero and negative gradients, and the maximum bounded trace. The batch sequence preserves the source's per-step state while using the available `i64_array_bytes_output` ABI.

Build with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm adagrad --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/adagrad/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm adagrad --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/adagrad.c`](../../../c/a/adagrad.c) |
| C3 | [`c3/a/adagrad.c3`](../../../c3/a/adagrad.c3) |
| C++ | [`cpp/a/adagrad.cpp`](../../../cpp/a/adagrad.cpp) |
| Elisa | [`elisa/a/adagrad.elisa`](../../../elisa/a/adagrad.elisa) |
| Nim | [`nim/a/adagrad.nim`](../../../nim/a/adagrad.nim) |
| Odin | [`odin/a/adagrad.odin`](../../../odin/a/adagrad.odin) |
| Rust | [`rust/a/adagrad.rs`](../../../rust/a/adagrad.rs) |
| V | [`v/a/adagrad.v`](../../../v/a/adagrad.v) |
| Zig | [`zig/a/adagrad.zig`](../../../zig/a/adagrad.zig) |

## Reviewed source

- [Python `adagrad.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/optimizers/adagrad.py)
