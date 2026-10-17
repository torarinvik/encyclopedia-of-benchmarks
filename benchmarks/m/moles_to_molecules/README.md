# Moles to molecules

Convert a quantity in moles to a rounded molecule count. This package isolates
`moles_to_molecules(moles)` from the other helpers in the pinned
[TheAlgorithms/Python `molecular_chemistry.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/molecular_chemistry.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Contract

The `i64_array_float64` input is `[moles_micro]`, one signed 64-bit integer
representing micro-moles. Convert it to binary64 moles by dividing by
`1_000_000.0`. The bounded range is 0..2,000,000 micro-moles (0..2 mol).

Preserve the source's conversion order: multiply the binary64 moles value by
`6.022e23`, format that binary64 product with Python's `.4e` scientific
format (four digits after the decimal, five significant digits), then parse
the formatted string back to binary64. A 175 micro-mole case lands exactly on
a decimal halfway value and checks Python's ties-to-even formatting. Negative
or out-of-range input and malformed lengths return the finite sentinel
`-1e300`. Results are checked with absolute and relative tolerances of `1e-12`.
The C port selects the five decimal digits with exact nearest-even integer
rounding, then uses `strtod` to parse that decimal value under the runtime's
default binary64 rounding mode.

[`workload.json`](workload.json) includes the pinned 2-mole and half-mole
examples, zero, one and quarter mole, a micro-mole input, a nontrivial scaled
input, a decimal halfway case, the upper bound, and malformed or out-of-range
inputs. The independent oracle is
[`benchmarks/moles_to_molecules_oracle.py`](../../moles_to_molecules_oracle.py).

Build and record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm moles_to_molecules --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/moles_to_molecules/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm moles_to_molecules --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/moles_to_molecules.c`](../../../c/m/moles_to_molecules.c) |
| C3 | [`c3/m/moles_to_molecules.c3`](../../../c3/m/moles_to_molecules.c3) |
| C++ | [`cpp/m/moles_to_molecules.cpp`](../../../cpp/m/moles_to_molecules.cpp) |
| Elisa | [`elisa/m/moles_to_molecules.elisa`](../../../elisa/m/moles_to_molecules.elisa) |
| Nim | [`nim/m/moles_to_molecules.nim`](../../../nim/m/moles_to_molecules.nim) |
| Odin | [`odin/m/moles_to_molecules.odin`](../../../odin/m/moles_to_molecules.odin) |
| Rust | [`rust/m/moles_to_molecules.rs`](../../../rust/m/moles_to_molecules.rs) |
| V | [`v/m/moles_to_molecules.v`](../../../v/m/moles_to_molecules.v) |
| Zig | [`zig/m/moles_to_molecules.zig`](../../../zig/m/moles_to_molecules.zig) |
