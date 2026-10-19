# BitBench drop3

`drop3` filters an encoded stream by walking the upstream 3-bit offset schedule `(0, 5, 2, 7, 4, 1, 6, 3)`, retaining codes whose value is at least four, and packing the retained codes. The source repeats the same filter 20 times and prints the packed byte count; the port keeps those 20 passes and returns that count as a scalar.

The bounded input is a signed 64-bit array of bytes in `[0, 255]`, with at most 4096 bytes. Empty input is valid and returns zero. Other malformed or oversized inputs return `-1`. This bound keeps the source's linear bitstream scan manageable while testing the same offset and drop behavior.

The independent Python source-order oracle is [`benchmarks/drop3_oracle.py`](../../drop3_oracle.py). The pinned source is [`BitBench/drop3/drop3.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/drop3/drop3.c).

Build a language implementation with the `i64_array_scalar` ABI family, for example:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm drop3 --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/drop3/rust/build.json
```
