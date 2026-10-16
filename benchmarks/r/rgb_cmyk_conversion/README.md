# RGB to CMYK conversion

This benchmark follows the pinned Python `rgb_to_cmyk` function, which converts integer RGB channels to four CMYK percentage values.

## Contract

- Input is exactly three signed 64-bit integers `[red, green, blue]`, each in `[0,255]`. Invalid shape or channel values return `-1`.
- Output is four bytes in `[cyan, magenta, yellow, black]` order. Each byte is the corresponding integer percentage in `[0,100]`. Output capacity below four bytes returns `-2`; success returns `4`.
- The conversion uses the source's floating-point normalization and formula order, special-cases pure black, and follows Python `round` ties-to-even behavior.
- The matching Rust file implements the same direction but truncates floating-point values when casting to `u8`; it diverges on cases such as gray `(128,128,128)` (Python K=50, Rust K=49), so the bounded benchmark contract follows Python.
- The pinned Python module exports only RGB-to-CMYK. It contains no reverse CMYK-to-RGB function.

## Source

Pinned source: [TheAlgorithms/Python `rgb_cmyk_conversion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/rgb_cmyk_conversion.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The matching-direction Rust implementation is [pinned here](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/rgb_cmyk_conversion.rs); its integer conversion truncates instead of using Python's ties-to-even rounding.

## Workload and running

[`workload.json`](workload.json) covers the source examples, primary and tied channels, the Python/Rust gray divergence, invalid channels and lengths, and exact/undersized output capacity. The independent oracle is [`benchmarks/rgb_cmyk_conversion_oracle.py`](../../rgb_cmyk_conversion_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rgb_cmyk_conversion --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm rgb_cmyk_conversion --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rgb_cmyk_conversion.c`](../../../c/rgb_cmyk_conversion.c) |
| C3 | [`c3/r/rgb_cmyk_conversion.c3`](../../../c3/rgb_cmyk_conversion.c3) |
| C++ | [`cpp/r/rgb_cmyk_conversion.cpp`](../../../cpp/r/rgb_cmyk_conversion.cpp) |
| Elisa | [`elisa/r/rgb_cmyk_conversion.elisa`](../../../elisa/r/rgb_cmyk_conversion.elisa) |
| Nim | [`nim/r/rgb_cmyk_conversion.nim`](../../../nim/r/rgb_cmyk_conversion.nim) |
| Odin | [`odin/r/rgb_cmyk_conversion.odin`](../../../odin/r/rgb_cmyk_conversion.odin) |
| Rust | [`rust/r/rgb_cmyk_conversion.rs`](../../../rust/r/rgb_cmyk_conversion.rs) |
| V | [`v/r/rgb_cmyk_conversion.v`](../../../v/r/rgb_cmyk_conversion.v) |
| Zig | [`zig/r/rgb_cmyk_conversion.zig`](../../../zig/r/rgb_cmyk_conversion.zig) |
