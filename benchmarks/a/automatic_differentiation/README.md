# Automatic differentiation

This package computes the derivative of one selected scalar output with respect to one input leaf by reverse-mode automatic differentiation. Its operation tape is a bounded, portable interface to the scalar operations in the pinned Python source.

## Contract

The `i64_array_float64` ABI input is:

```text
[leaf_count, operation_count, target_node, source_leaf,
 leaf_values..., (opcode, left_node, right_node_or_exponent)...]
```

There are 1–32 leaves and 1–64 operations. Leaf values are in `-16..16`. Every operation creates the next node and can only refer to earlier nodes. The target must be an operation output; `source_leaf` selects an input leaf. Operation codes are 0 add, 1 subtract, 2 multiply, 3 divide, and 5 integer power. Power stores its exponent in the third field and accepts exponents 1–8. Division by zero, intermediate magnitudes above `10^10`, malformed tapes, and a source leaf disconnected from the target return `-1e300`.

The output is the binary64 derivative `d(target)/d(source_leaf)`. The ports use reverse accumulation over the topologically ordered tape, so a shared intermediate receives and propagates the sum of all downstream adjoints. This also handles repeated operands, such as `x * x`, by accumulating both operand contributions.

## Source behavior

The pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/automatic_differentiation.py) implements reverse-mode differentiation for scalar and array variables and includes matrix multiplication. This package covers scalar add, subtract, multiply, divide, and integer power; matrix operations are outside its ABI.

The source appends an operation reference once for every input occurrence, then reads an output node's accumulated partial derivative each time that operation is popped. On a shared intermediate DAG this can propagate the same accumulated adjoint more than once. The package corrects that behavior and follows the reverse-mode chain rule. The `shared_intermediate` workload case records this correction; tree-shaped graphs without shared intermediate fanout retain the pinned source result.

## Workload and build

[`workload.json`](workload.json) includes source examples, repeated operands, shared intermediates, all supported scalar operations, disconnected sources, and invalid inputs. Expected values are checked by the independent [operation-tape oracle](../../automatic_differentiation_oracle.py). Results use absolute and relative tolerances of `1e-12`.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm automatic_differentiation --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/a/automatic_differentiation/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/a/automatic_differentiation.c`](../../../c/a/automatic_differentiation.c) |
| C3 | [`c3/a/automatic_differentiation.c3`](../../../c3/a/automatic_differentiation.c3) |
| C++ | [`cpp/a/automatic_differentiation.cpp`](../../../cpp/a/automatic_differentiation.cpp) |
| Elisa | [`elisa/a/automatic_differentiation.elisa`](../../../elisa/a/automatic_differentiation.elisa) |
| Nim | [`nim/a/automatic_differentiation.nim`](../../../nim/a/automatic_differentiation.nim) |
| Odin | [`odin/a/automatic_differentiation.odin`](../../../odin/a/automatic_differentiation.odin) |
| Rust | [`rust/a/automatic_differentiation.rs`](../../../rust/a/automatic_differentiation.rs) |
| V | [`v/a/automatic_differentiation.v`](../../../v/a/automatic_differentiation.v) |
| Zig | [`zig/a/automatic_differentiation.zig`](../../../zig/a/automatic_differentiation.zig) |
