# NOT Gate

Return `1` for input `0` and `0` for input `1`.

## Contract

- The input is an integer encoded as `0` or `1`; values outside this domain are outside the benchmark contract.
- The workload contains both possible inputs.
- The implementation uses portable integer comparison and does not depend on CPU-specific instructions or libraries.

## Source

The pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/boolean_algebra/not_gate.py) defines this unary Boolean gate. The benchmark preserves its 0/1 mapping.

Build with the shared scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm not_gate --language rust
```

The build writes a manifest under `build/scalar/n/not_gate/rust/build.json`. Use the generated source, compiler, and runner provenance values from that manifest with [`run_scalar.py`](../../run_scalar.py); its command line is documented by `python3 benchmarks/run_scalar.py --help`.
