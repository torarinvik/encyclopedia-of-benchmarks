# Max pooling

This benchmark ports only the pinned Python `maxpooling` function from `pooling_functions.py`. It excludes `avgpooling` and the image-loading demo.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[n, size, stride, matrix values...]` as signed-i32 words, with exactly `3 + n*n` words. The matrix is square and row-major; `n` is 1–16, `size` is 1–`n`, `stride` is 1–16, and every pixel is in `[-1,000,000, 1,000,000]`.
- Each output element is the maximum of a full `size × size` window. The source visits window origins at multiples of `stride`, advances rows and columns independently, and drops positions where the full window would exceed the matrix. There is no padding. The output side length is `(n - size) // stride + 1`.
- Output is the row-major max-pooled matrix serialized as little-endian IEEE-754 f64 values, with no shape prefix. The bounded integer pixels convert exactly to f64. Output length ranges from 8 to 2,048 bytes; at most 259 input words are accepted. Invalid or null input returns `-1` before output-buffer checks. A null output or insufficient capacity returns `-2` without writes.

The workload covers stride and window boundaries, negative pixels, non-divisible dimensions, full-window behavior without padding, maximum input/output, malformed arrays, and output capacity. See [workload.json](workload.json) and the independent [oracle](../../max_pooling_oracle.py).

Pinned source: [TheAlgorithms/Python `pooling_functions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/computer_vision/pooling_functions.py), function `maxpooling`, at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm max_pooling --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/m/max_pooling/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithms max_pooling --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/max_pooling.c](../../../c/m/max_pooling.c) |
| C3 | [c3/m/max_pooling.c3](../../../c3/m/max_pooling.c3) |
| C++ | [cpp/m/max_pooling.cpp](../../../cpp/m/max_pooling.cpp) |
| Elisa | [elisa/m/max_pooling.elisa](../../../elisa/m/max_pooling.elisa) |
| Nim | [nim/m/max_pooling.nim](../../../nim/m/max_pooling.nim) |
| Odin | [odin/m/max_pooling.odin](../../../odin/m/max_pooling.odin) |
| Rust | [rust/m/max_pooling.rs](../../../rust/m/max_pooling.rs) |
| V | [v/m/max_pooling.v](../../../v/m/max_pooling.v) |
| Zig | [zig/m/max_pooling.zig](../../../zig/m/max_pooling.zig) |
