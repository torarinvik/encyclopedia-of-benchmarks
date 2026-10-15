# Snell's law (degrees)

Calculate the refracted angle for the pinned Python implementation. The incident angle and result use degrees, and valid results are rounded to two decimal places. This is separate from [`snell_law`](../snell_law/README.md), which follows the Java source and uses radians without rounding.

## Contract

The `float64_triple` input is `[n1, n2, incident_angle_degrees]`. Each refractive index must be finite and in `[0.5, 2.5]`; the incident angle must be finite and in `[-90, 90]` degrees. The ports preserve the source operation order: convert degrees to radians, compute `(n1 / n2) * sin(angle)`, return exactly `90` or `-90` when that sine is `math.isclose` to `1` or `-1` using Python's default relative tolerance, reject values outside `[-1, 1]`, then convert `asin` back to degrees and round to two decimal places using ties-to-even. Invalid or total-internal-reflection inputs return `-1e300`.

## Workload and build

[`workload.json`](workload.json) covers ordinary refraction in both directions, negative and grazing angles, the source's near-critical `isclose` behavior, total internal reflection, and invalid inputs.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm snells_law --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/s/snells_law/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/snells_law.c`](../../../c/s/snells_law.c) |
| C3 | [`c3/s/snells_law.c3`](../../../c3/s/snells_law.c3) |
| C++ | [`cpp/s/snells_law.cpp`](../../../cpp/s/snells_law.cpp) |
| Elisa | [`elisa/s/snells_law.elisa`](../../../elisa/s/snells_law.elisa) |
| Nim | [`nim/s/snells_law.nim`](../../../nim/s/snells_law.nim) |
| Odin | [`odin/s/snells_law.odin`](../../../odin/s/snells_law.odin) |
| Rust | [`rust/s/snells_law.rs`](../../../rust/s/snells_law.rs) |
| V | [`v/s/snells_law.v`](../../../v/s/snells_law.v) |
| Zig | [`zig/s/snells_law.zig`](../../../zig/s/snells_law.zig) |

## Pinned source

- Python [`snells_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/snells_law.py)
- Related Java radians benchmark: [`snell_law`](../snell_law/README.md)
