# Hubble Parameter

This benchmark follows the pinned Python cosmology calculation of the expansion rate as a function of redshift and the radiation, matter, and dark-energy densities.

## Contract

- The `i64_array_float64` ABI supplies exactly `[H0_x10, omega_r_ppm, omega_m_ppm, omega_de_ppm, z_milli]` as signed 64-bit integers. Decode the fields by dividing by `10`, `1,000,000`, `1,000,000`, `1,000,000`, and `1,000`, respectively.
- Require `H0_x10` in `[-2000,2000]`, each encoded density in `[0,1,000,000]`, their sum at most `1,000,000`, and `z_milli` in `[0,10,000]`. These bounds keep the curvature nonnegative and all powers/results finite. The integer scale factors make the packed inputs exact.
- Preserve source order: `curvature = 1 - (matter + radiation + dark_energy)`, `e2 = radiation*(z+1)^4 + matter*(z+1)^3 + curvature*(z+1)^2 + dark_energy`, then `H0 * e2**(1/2)`. Results use relative and absolute tolerance `1e-12`.
- The pinned function validates redshift and density fields but does not validate the Hubble constant. Therefore zero and negative `H0` are valid here and retain their zero or signed results. A null input pointer, malformed layout, out-of-range encoding, or density total above the contract returns `-1e300`.

The density-sum restriction selects the nonnegative-curvature subset of the source domain. The `-1e300` sentinel is outside the bounded valid output range, including for negative Hubble constants.

## Source

- [TheAlgorithms/Python `physics/hubble_parameter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/hubble_parameter.py)

## Workload and integration

[`workload.json`](workload.json) covers the source example's expansion inputs, zero and negative Hubble constants, radiation/matter/dark-energy mixes, nonzero curvature, redshift bounds, and invalid inputs. The source-ordered oracle is wired into the shared `i64_array_float64` recorder, which checks every listed expected value before measurement.

Verify all nine ports against the bounded generated corpus and every workload case:

```sh
python3 benchmarks/verify_i64_array_float64.py --algorithm hubble_parameter
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/h/hubble_parameter.c`](../../../c/h/hubble_parameter.c) |
| C3 | [`c3/h/hubble_parameter.c3`](../../../c3/h/hubble_parameter.c3) |
| C++ | [`cpp/h/hubble_parameter.cpp`](../../../cpp/h/hubble_parameter.cpp) |
| Elisa | [`elisa/h/hubble_parameter.elisa`](../../../elisa/h/hubble_parameter.elisa) |
| Nim | [`nim/h/hubble_parameter.nim`](../../../nim/h/hubble_parameter.nim) |
| Odin | [`odin/h/hubble_parameter.odin`](../../../odin/h/hubble_parameter.odin) |
| Rust | [`rust/h/hubble_parameter.rs`](../../../rust/h/hubble_parameter.rs) |
| V | [`v/h/hubble_parameter.v`](../../../v/h/hubble_parameter.v) |
| Zig | [`zig/h/hubble_parameter.zig`](../../../zig/h/hubble_parameter.zig) |
