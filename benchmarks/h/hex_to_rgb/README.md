# Hex color to packed RGB

Convert a six-digit hexadecimal RGB color into one packed integer. This shared domain is supported by both pinned conversion sources.

## Contract

The `i64_array_scalar` input is exactly six ASCII hexadecimal digit codes in `RRGGBB` order, with no leading `#`. Uppercase and lowercase digits are accepted. Return the packed value `(red << 16) | (green << 8) | blue`, in the range 0 through 16,777,215. Wrong length, non-ASCII, or non-hex input returns `-1`.

The Python source also supports three-digit colors and an optional leading `#`; the JavaScript source takes an unprefixed six-character string. Restricting the contract to six unprefixed digits preserves their common conversion behavior. The output packs the RGB components because the source variants return different container types.

## Sources

- JavaScript [`HexToRGB.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/HexToRGB.js) parses three two-digit components and returns an object.
- Python [`hex_to_rgb.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/hex_to_rgb.py) parses six-digit colors and formats an `rgb(...)` string.

## Workload and recording

[`workload.json`](workload.json) covers primary colors, mixed-case hexadecimal, malformed lengths, and invalid characters.

The shared `i64_array_scalar` runner checks each declared result against the packed value of the six hexadecimal digits, returning `-1` for malformed input.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hex_to_rgb --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hex_to_rgb/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/h/hex_to_rgb.c`](../../../c/h/hex_to_rgb.c) |
| C3 | [`c3/h/hex_to_rgb.c3`](../../../c3/h/hex_to_rgb.c3) |
| C++ | [`cpp/h/hex_to_rgb.cpp`](../../../cpp/h/hex_to_rgb.cpp) |
| Elisa | [`elisa/h/hex_to_rgb.elisa`](../../../elisa/h/hex_to_rgb.elisa) |
| Nim | [`nim/h/hex_to_rgb.nim`](../../../nim/h/hex_to_rgb.nim) |
| Odin | [`odin/h/hex_to_rgb.odin`](../../../odin/h/hex_to_rgb.odin) |
| Rust | [`rust/h/hex_to_rgb.rs`](../../../rust/h/hex_to_rgb.rs) |
| V | [`v/h/hex_to_rgb.v`](../../../v/h/hex_to_rgb.v) |
| Zig | [`zig/h/hex_to_rgb.zig`](../../../zig/h/hex_to_rgb.zig) |
