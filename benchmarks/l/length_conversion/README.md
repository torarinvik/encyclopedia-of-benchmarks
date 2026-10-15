# Length conversion

Convert a finite length between the four metric units shared by the pinned JavaScript, Julia, Python, and Rust sources.

## Contract

- The `float64_triple` ABI accepts `[value, from_unit, to_unit]` as three binary64 inputs.
- Unit selectors are `0=mm`, `1=cm`, `2=m`, and `3=km`. These numeric selectors give the string-based and enum-based sources one portable interface.
- `value` must be finite and within `[-1,000,000, 1,000,000]`; both unit selectors must be exactly one of `0`, `1`, `2`, or `3`. Invalid inputs return `-1e300`.
- The conversion expression is `(value * meters_per_from_unit) / meters_per_to_unit`, with factors `[0.001, 0.01, 1.0, 1000.0]`. Compare results using the declared input-scaled tolerance `1e-12`.

## Source semantics

All four pinned sources convert through meters and cover the same eight physical units. This benchmark uses their shared metric subset. JavaScript and Rust divide by the destination meter factor; Python and Julia multiply by a precomputed reciprocal. The metric subset avoids their rounded imperial reciprocals, while the tolerance covers small binary64 rounding differences between those operation orders. Unit names, aliases, and case-normalization behavior are outside this numeric-selector contract.

## Workload and reproduction

[`workload.json`](workload.json) covers each metric scale, negative and fractional values, zero, identity conversion, the maximum bounded output, and invalid values or selectors.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm length_conversion --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/l/length_conversion/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/length_conversion.c`](../../../c/l/length_conversion.c) |
| C3 | [`c3/l/length_conversion.c3`](../../../c3/l/length_conversion.c3) |
| C++ | [`cpp/l/length_conversion.cpp`](../../../cpp/l/length_conversion.cpp) |
| Elisa | [`elisa/l/length_conversion.elisa`](../../../elisa/l/length_conversion.elisa) |
| Nim | [`nim/l/length_conversion.nim`](../../../nim/l/length_conversion.nim) |
| Odin | [`odin/l/length_conversion.odin`](../../../odin/l/length_conversion.odin) |
| Rust | [`rust/l/length_conversion.rs`](../../../rust/l/length_conversion.rs) |
| V | [`v/l/length_conversion.v`](../../../v/l/length_conversion.v) |
| Zig | [`zig/l/length_conversion.zig`](../../../zig/l/length_conversion.zig) |

## Pinned sources

- [JavaScript `LengthConversion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/LengthConversion.js)
- [Julia `length_conversion.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/conversions/length_conversion.jl)
- [Python `length_conversion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/length_conversion.py)
- [Rust `length_conversion.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/length_conversion.rs)
