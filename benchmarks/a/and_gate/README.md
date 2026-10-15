# AND Gate

Compute the two-input Boolean AND for integer inputs encoded as `0` or `1`. The result is `1` only when both inputs are `1`; otherwise it is `0`.

## Contract

- Both inputs must be in `{0, 1}`. Inputs outside that set are outside this benchmark contract.
- Each of the four possible input pairs appears in the workload.
- The implementations use portable integer bitwise AND, without architecture-specific instructions or libraries.

## Source

The pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/boolean_algebra/and_gate.py) validates the two inputs as integers in `{0, 1}` and returns their bitwise AND. The benchmark ports the named two-input function; the upstream file also contains a separate n-input helper.

Build and record with the shared two-input scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm and_gate --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/a/and_gate/rust/build.json
```
