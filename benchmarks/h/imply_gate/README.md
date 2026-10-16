# IMPLY Gate

Compute Boolean implication for two Boolean integer inputs. The result is false only when the left input is true and the right input is false.

## Contract

The shared `binary_scalar` ABI accepts each input as `0` or `1`; values outside this set are outside the benchmark contract. The function returns `1` when `left == 0 || right == 1`, otherwise `0`. The four truth-table rows are included in the workload. The operation uses O(1) time and space.

This ports the named `imply_gate` function from the pinned Python module; the upstream module also includes a separate left-to-right recursive list operation, which is not part of this two-input benchmark.

Pinned source: [TheAlgorithms/Python `imply_gate.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/boolean_algebra/imply_gate.py).

Build and record with the shared two-input scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm imply_gate --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/h/imply_gate/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/imply_gate.c`](../../../c/h/imply_gate.c) |
| C3 | [`c3/h/imply_gate.c3`](../../../c3/h/imply_gate.c3) |
| C++ | [`cpp/h/imply_gate.cpp`](../../../cpp/h/imply_gate.cpp) |
| Elisa | [`elisa/h/imply_gate.elisa`](../../../elisa/h/imply_gate.elisa) |
| Nim | [`nim/h/imply_gate.nim`](../../../nim/h/imply_gate.nim) |
| Odin | [`odin/h/imply_gate.odin`](../../../odin/h/imply_gate.odin) |
| Rust | [`rust/h/imply_gate.rs`](../../../rust/h/imply_gate.rs) |
| V | [`v/h/imply_gate.v`](../../../v/h/imply_gate.v) |
| Zig | [`zig/h/imply_gate.zig`](../../../zig/h/imply_gate.zig) |
