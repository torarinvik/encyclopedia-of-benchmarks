# Change contrast

The pinned Python function computes `factor = 259 * (level + 255) / (255 * (259 - level))`, maps each channel around 128, and converts the mapped value with `int()`, which truncates toward zero. Its `Image.point` operation applies the mapping to the image's byte channels. The source has no explicit level bound; this portable contract uses levels from -255 through 255 so the denominator stays positive and bounded.

## Contract

- The `i64_array_bytes_output` ABI accepts `[level, channel_byte...]` with 1 through 4,096 signed 64-bit values. The first value must be in `[-255, 255]`; remaining values must be bytes.
- For each channel, compute `128 + factor * (channel - 128)`, truncate toward zero, then clip to `[0, 255]`.
- An input with only a level is valid and returns zero output bytes. Invalid inputs return `-1`; insufficient output capacity returns `-2` without writing.
- The maximum output is 4,095 bytes.

[`workload.json`](workload.json) covers every byte channel at neutral contrast, low and high contrast, truncation toward zero, clipping, invalid inputs, empty images, and insufficient capacity. The verifier checks all 256 channel bytes for each of the 511 legal levels. All nine ports passed 529 oracle inputs and 13 workload cases.

```sh
python3.12 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm change_contrast --language rust
python3.12 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/change_contrast/rust/build.json
python3.12 benchmarks/verify_i64_array_bytes_output.py --algorithm change_contrast
```

| Language | Source |
| --- | --- |
| C | [`c/c/change_contrast.c`](../../../c/c/change_contrast.c) |
| C3 | [`c3/c/change_contrast.c3`](../../../c3/c/change_contrast.c3) |
| C++ | [`cpp/c/change_contrast.cpp`](../../../cpp/c/change_contrast.cpp) |
| Elisa | [`elisa/c/change_contrast.elisa`](../../../elisa/c/change_contrast.elisa) |
| Nim | [`nim/c/change_contrast.nim`](../../../nim/c/change_contrast.nim) |
| Odin | [`odin/c/change_contrast.odin`](../../../odin/c/change_contrast.odin) |
| Rust | [`rust/c/change_contrast.rs`](../../../rust/c/change_contrast.rs) |
| V | [`v/c/change_contrast.v`](../../../v/c/change_contrast.v) |
| Zig | [`zig/c/change_contrast.zig`](../../../zig/c/change_contrast.zig) |

## TheAlgorithms reference

- [Python `change_contrast.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/change_contrast.py)
