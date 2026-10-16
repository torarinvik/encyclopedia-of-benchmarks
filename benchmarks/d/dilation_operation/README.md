# Dilation Operation

This benchmark ports the `dilation` function from TheAlgorithms/Python's image morphology module. For each image cell, it multiplies the corresponding 3×3 neighborhood by the structuring element and emits 1 if the sum is positive, otherwise 0.

## Contract

- The `i64_array_bytes_output` input is `[rows, columns, image cells row-major, kernel cells row-major]`, with exactly `2 + rows*columns + 9` signed 64-bit slots.
- Rows and columns are in `1..16`. Image cells and the fixed 3×3 kernel cells are binary integers, 0 or 1.
- The image is placed in a zero-padded border at offset `(1,1)`, matching the pinned source's `kernel_dimension - 2` placement for a 3×3 kernel. Each output cell is `int(sum(kernel * window) > 0)`. The kernel is applied in its source order, without flipping.
- Output is a row-major matrix of signed 32-bit 0/1 values, each little-endian. A successful call returns the number of output cells and writes `4*rows*columns` bytes. Invalid input returns `-1`; insufficient output capacity or a null output buffer returns `-2`.

The benchmark fixes the kernel at 3×3. This matches the source's intended structuring-element use and avoids the source's invalid slicing behavior for a dimension-1 kernel. Binary cells preserve its `sum > 0` predicate while keeping the shared integer ABI exact.

This is dilation; it is distinct from erosion, which requires every active kernel position to overlap an active image cell.

## Pinned source

- Python [`dilation_operation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/morphological_operations/dilation_operation.py)

## Workload and build

[`workload.json`](workload.json) covers a centered cross, edge padding, a 1×1 image, asymmetric kernel orientation, empty foreground, and invalid dimensions/cells/capacity. The package uses `i64_array_bytes_output`:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm dilation_operation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/dilation_operation/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm dilation_operation
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/d/dilation_operation.c`](../../../c/d/dilation_operation.c) |
| C3 | [`c3/d/dilation_operation.c3`](../../../c3/d/dilation_operation.c3) |
| C++ | [`cpp/d/dilation_operation.cpp`](../../../cpp/d/dilation_operation.cpp) |
| Elisa | [`elisa/d/dilation_operation.elisa`](../../../elisa/d/dilation_operation.elisa) |
| Nim | [`nim/d/dilation_operation.nim`](../../../nim/d/dilation_operation.nim) |
| Odin | [`odin/d/dilation_operation.odin`](../../../odin/d/dilation_operation.odin) |
| Rust | [`rust/d/dilation_operation.rs`](../../../rust/d/dilation_operation.rs) |
| V | [`v/d/dilation_operation.v`](../../../v/d/dilation_operation.v) |
| Zig | [`zig/d/dilation_operation.zig`](../../../zig/d/dilation_operation.zig) |
