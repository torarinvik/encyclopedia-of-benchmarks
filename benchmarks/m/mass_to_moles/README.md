# Mass to moles

Convert a substance's mass and molar mass to moles, rounded to two decimal
places. This package isolates `mass_to_moles(mass, molar_mass)` from the other
helpers in the pinned
[TheAlgorithms/Python `molecular_chemistry.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/molecular_chemistry.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Contract

The `i64_array_float64` input is `[mass, molar_mass]` with exactly two signed
64-bit integers. They represent integer-valued numeric arguments and are
converted exactly to binary64. Valid mass values are 0..1000 and valid molar
masses are 1..1000.

The result is the source expression `round(float(mass / molar_mass), 2)`,
returned as binary64. Rounding applies to the binary64 quotient produced by
division, not to the exact rational ratio. Preserve Python's ties-to-even
behavior: `1 / 8 = 0.125` rounds to `0.12`, while `3 / 8 = 0.375` rounds to
`0.38`. The binary64 quotient for `107 / 40` is just below `2.675` and rounds
to `2.67`; the quotient for `1 / 40` is just above `0.025` and rounds to
`0.03`. The result is checked with absolute and relative tolerances of
`1e-12`.
Invalid lengths, negative mass, nonpositive molar mass, or values outside the
bounded domain return the finite sentinel `-1e300`.

[`workload.json`](workload.json) covers zero and exact ratios, a repeating
decimal, ties-to-even cases, the maximum bounded quotient, and malformed or
out-of-range inputs. The independent oracle is
[`benchmarks/mass_to_moles_oracle.py`](../../mass_to_moles_oracle.py).

Build and record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm mass_to_moles --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/mass_to_moles/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm mass_to_moles --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/mass_to_moles.c`](../../../c/m/mass_to_moles.c) |
| C3 | [`c3/m/mass_to_moles.c3`](../../../c3/m/mass_to_moles.c3) |
| C++ | [`cpp/m/mass_to_moles.cpp`](../../../cpp/m/mass_to_moles.cpp) |
| Elisa | [`elisa/m/mass_to_moles.elisa`](../../../elisa/m/mass_to_moles.elisa) |
| Nim | [`nim/m/mass_to_moles.nim`](../../../nim/m/mass_to_moles.nim) |
| Odin | [`odin/m/mass_to_moles.odin`](../../../odin/m/mass_to_moles.odin) |
| Rust | [`rust/m/mass_to_moles.rs`](../../../rust/m/mass_to_moles.rs) |
| V | [`v/m/mass_to_moles.v`](../../../v/m/mass_to_moles.v) |
| Zig | [`zig/m/mass_to_moles.zig`](../../../zig/m/mass_to_moles.zig) |
