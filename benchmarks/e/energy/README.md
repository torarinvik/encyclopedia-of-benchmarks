# Energy Conversion

This benchmark ports the Rust `convert_energy` function from `src/conversions/energy.rs` at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. It converts the source amount to joules, then divides by the target unit's joule factor.

## Contract

- The `i64_array_float64` input is `[value_micro, from_unit, to_unit]`; `value_micro` is divided by 1,000,000 before conversion.
- `value_micro` is bounded to `[-1,000,000,000,000, 1,000,000,000,000]` (physical values `[-1,000,000, 1,000,000]`). Unit codes are the enum declaration order below, 0 through 54.
- The parser admits four packed values so an extra-value malformed record reaches the adapter; valid input has exactly three values. Invalid input returns `-1e300`.
- All outputs remain finite on the bounded domain; the largest factor ratio gives an output below `4.184e42`. Ports preserve the source order: `joules = value * source_factor`, then `output = joules / target_factor`. The same 55 source constants index the factor table for both steps. The source's grouped arms are preserved in the mapping, including `CalorieNutritional` and `KilocalorieIT` both using 4,186.8 and `KilocalorieNutritional` using 4,186,800.
- The source algorithm uses constant-time enum dispatch and one multiplication followed by one division; the ports use the same ordered factor mapping.

## Unit codes

```text
0 = Joule
1 = Kilojoule
2 = Megajoule
3 = Gigajoule
4 = Millijoule
5 = Microjoule
6 = Nanojoule
7 = Attojoule
8 = WattSecond
9 = WattHour
10 = KilowattSecond
11 = KilowattHour
12 = MegawattHour
13 = GigawattHour
14 = NewtonMeter
15 = Erg
16 = DyneCentimeter
17 = CalorieNutritional
18 = KilocalorieNutritional
19 = CalorieIT
20 = KilocalorieIT
21 = CalorieTh
22 = KilocalorieTh
23 = Electronvolt
24 = Kiloelectronvolt
25 = Megaelectronvolt
26 = BtuIT
27 = BtuTh
28 = MegaBtuIT
29 = FootPound
30 = PoundForceFoot
31 = PoundForceInch
32 = InchPound
33 = InchOunce
34 = OunceForceInch
35 = PoundalFoot
36 = HorsepowerHour
37 = HorsepowerMetricHour
38 = KilogramForceMeter
39 = KilogramForceCentimeter
40 = KilopondMeter
41 = GramForceMeter
42 = GramForceCentimeter
43 = Therm
44 = ThermEC
45 = ThermUS
46 = TonHourRefrigeration
47 = FuelOilEquivalentKiloliter
48 = FuelOilEquivalentBarrel
49 = TonExplosives
50 = Kiloton
51 = Megaton
52 = Gigaton
53 = HartreeEnergy
54 = RydbergConstant
```

## Pinned source

Rust [`energy.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/energy.rs) at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Workload and build

[`workload.json`](workload.json) exercises every unit as both source and destination, same-unit conversions, source factor extremes, signed values, bounds, and malformed input. The independent oracle is [`energy_oracle.py`](../../energy_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm energy --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/e/energy/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithms energy
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/energy.c`](../../../c/e/energy.c) |
| C3 | [`c3/e/energy.c3`](../../../c3/e/energy.c3) |
| C++ | [`cpp/e/energy.cpp`](../../../cpp/e/energy.cpp) |
| Elisa | [`elisa/e/energy.elisa`](../../../elisa/e/energy.elisa) |
| Nim | [`nim/e/energy.nim`](../../../nim/e/energy.nim) |
| Odin | [`odin/e/energy.odin`](../../../odin/e/energy.odin) |
| Rust | [`rust/e/energy.rs`](../../../rust/e/energy.rs) |
| V | [`v/e/energy.v`](../../../v/e/energy.v) |
| Zig | [`zig/e/energy.zig`](../../../zig/e/energy.zig) |
