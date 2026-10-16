# 2D array lookup by flat index

This benchmark measures the pinned Python function `index_2d_array_in_1d`: given a rectangular matrix and a zero-based flat index, return the value at that position in row-major order. It computes the row and column with integer division and remainder, then indexes the original matrix.

## Contract

- Pack signed 64-bit integers as `[rows, cols, index, values...]`, followed by exactly `rows * cols` matrix values in row-major order.
- `rows` and `cols` are each in `1..=32`; `index` is in `0..rows*cols-1`; values are in `0..=1,000,000`.
- Return the selected value as a signed 64-bit scalar. Invalid dimensions, index, packing, or values return `-1`.

The source expects a nonempty rectangular matrix. Empty and ragged matrices cannot be represented by this packed input contract, so they are outside the valid domain. The nonnegative value bound keeps `-1` unambiguous as the ABI invalid-input result.

## Source and distinction

- [TheAlgorithms/Python `index_2d_array_in_1d.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/index_2d_array_in_1d.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

This operation maps a flat index to a matrix value. The related [`binary_search2d_array`](../binary_search2d_array/README.md) searches a sorted matrix for a value and returns its row-major position, so it has the opposite input/output direction. See [`workload.json`](workload.json) for row-major boundaries, singleton shape, and invalid packing cases.

Verify the ports and workload with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms index_2d_array_in_1d
```
