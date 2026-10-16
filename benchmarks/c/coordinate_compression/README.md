# Coordinate compression

The pinned Python `CoordinateCompressor` assigns zero-based coordinates to the sorted distinct values in its input. This benchmark normalizes its `compress(value)` method to return the coordinate for every original input element, preserving the input order.

## Contract

- Uses the `i64_array_bytes_output` ABI with packed input `[n, values...]`.
- `n` is in `0..=128`; values are signed 32-bit integers. This integer domain gives ordinary numeric ordering and equality, matching the source mapping without mixed-type comparison or numeric-equality edge cases.
- Sort the values, assign rank 0 to the smallest distinct value, and increment rank only when the value changes. Emit each input value's rank in original order as a little-endian signed 64-bit integer.
- Duplicate values share a rank. Empty input returns zero bytes.
- Malformed packing or out-of-domain values return `-1`; insufficient output capacity returns `-2`. Valid inputs return `8*n` bytes.
- The output workspace is 1,024 bytes, enough for all 128 ranks. The workload includes an undersized-capacity case.

For example, `[100, 10, 52, 83]` maps to `[3, 0, 1, 2]`. This benchmarks the source's `sorted(arr)` plus distinct-value coordinate map; it does not preserve the original values in the output.

## Pinned source

[TheAlgorithms/Python `coordinate_compression.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/coordinate_compression.py) sorts the input, assigns each unseen sorted value the next integer coordinate, and exposes `compress(original)` through a dictionary lookup. The benchmark applies that method to each original input value.

[`workload.json`](workload.json) covers the source example, duplicates, negative and boundary values, monotone and mixed input, empty/singleton inputs, and malformed/domain cases.

Build the Rust port and record its workload with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm coordinate_compression --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/coordinate_compression/rust/build.json
```

Verify all nine ports with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm coordinate_compression
```
