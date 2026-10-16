# Scaled Exponential Linear Unit

This benchmark follows the pinned NumPy SELU expression, preserving its defaults `alpha=1.6732` and `lambda=1.0507` and its positive/nonpositive branch:

- `lambda * x` when `x > 0`
- `lambda * alpha * (exp(x) - 1)` otherwise

## Contract

Input is `[count, alpha_micro, lambda_micro, x_micro...]` in the `i64_array_bytes_output` ABI. `count` is 0..256. Parameters are finite values in [-10,10] and elements are in [-20,20], represented at a scale of 1,000,000. The vector length must match `count`. Invalid input returns `-1`; insufficient output capacity returns `-2`.

The output stores one signed 64-bit little-endian integer per element, equal to the SELU result rounded as `floor(result * 1,000,000,000 + 0.5)`. This fixed-point encoding preserves 1e-9 output resolution while making the vector ABI deterministic across the nine target languages. Success returns `count * 8` bytes.

## Workload and source

[`workload.json`](workload.json) covers the pinned positive examples, negative/zero/positive branches, custom parameters, empty vectors, and malformed input. The runtime oracle is [`benchmarks/scaled_exponential_linear_unit_oracle.py`](../../scaled_exponential_linear_unit_oracle.py).

Pinned source: [TheAlgorithms/Python `scaled_exponential_linear_unit.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/scaled_exponential_linear_unit.py).

| Language | Port |
|---|---|
| C | [`c/s/scaled_exponential_linear_unit.c`](../../../c/s/scaled_exponential_linear_unit.c) |
| C3 | [`c3/s/scaled_exponential_linear_unit.c3`](../../../c3/s/scaled_exponential_linear_unit.c3) |
| C++ | [`cpp/s/scaled_exponential_linear_unit.cpp`](../../../cpp/s/scaled_exponential_linear_unit.cpp) |
| Elisa | [`elisa/s/scaled_exponential_linear_unit.elisa`](../../../elisa/s/scaled_exponential_linear_unit.elisa) |
| Nim | [`nim/s/scaled_exponential_linear_unit.nim`](../../../nim/s/scaled_exponential_linear_unit.nim) |
| Odin | [`odin/s/scaled_exponential_linear_unit.odin`](../../../odin/s/scaled_exponential_linear_unit.odin) |
| Rust | [`rust/s/scaled_exponential_linear_unit.rs`](../../../rust/s/scaled_exponential_linear_unit.rs) |
| V | [`v/s/scaled_exponential_linear_unit.v`](../../../v/s/scaled_exponential_linear_unit.v) |
| Zig | [`zig/s/scaled_exponential_linear_unit.zig`](../../../zig/s/scaled_exponential_linear_unit.zig) |
