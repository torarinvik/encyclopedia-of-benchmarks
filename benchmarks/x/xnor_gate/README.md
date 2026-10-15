# Xnor Gate

1 when the inputs are equal; otherwise 0.

## Contract

- Each input is an integer encoded as `0` or `1`; values outside this domain are outside the benchmark contract.
- The workload contains the complete two-input truth table.
- The implementation uses portable integer operations and does not depend on CPU-specific instructions or libraries.

## Source

The pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/boolean_algebra/xnor_gate.py) defines this two-input Boolean gate. The contract preserves its 0/1 truth table.

Build and record with the shared two-input scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm xnor_gate --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/x/xnor_gate/rust/build.json
```
