# Charging capacitor voltage

This benchmark ports the pinned Python RC charging formula:

```text
round(source_voltage * (1 - exp(-time_sec / (resistance * capacitance))), 3)
```

The source rejects nonpositive source voltage, resistance, and capacitance. It does not reject negative time, so the benchmark keeps bounded negative-time inputs valid.

## Contract

The signed-i64 input is `[source_voltage_micro, resistance_micro, capacitance_micro, time_micro]`. Each field represents a real-valued quantity divided by 1,000,000. Source voltage is from 0.000001 through 1,000,000 volts, resistance from 0.000001 through 1,000,000,000 ohms, capacitance from 0.000001 through 1,000,000 farads, and time from -1,000,000 through 1,000,000 seconds.

The adapter also requires the computed exponential argument `-time_sec / (resistance * capacitance)` to be at most 10. This bounds negative-time growth so the exponential and returned voltage remain finite. Positive times remain valid across the full stated bounds, including cases where `exp` underflows to zero. Malformed, nonpositive-component, out-of-range, or over-bound exponential inputs return `-1e300`.

The shared ABI is:

```c
double charging_capacitor(const int64_t *values, size_t length);
```

[`workload.json`](workload.json) includes the four pinned examples, zero time, bounded negative time, the exponential-argument boundary, large positive time, rounding cases, and malformed inputs. The independent oracle is [`benchmarks/charging_capacitor_oracle.py`](../../charging_capacitor_oracle.py).

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm charging_capacitor --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_float64.py \
  --build-manifest build/i64_array_float64/c/charging_capacitor/rust/build.json
```

Verify the registered ports with:

```sh
python3 benchmarks/verify_charging_capacitor.py --languages rust
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/c/charging_capacitor.c`](../../../c/c/charging_capacitor.c) |
| C3 | [`c3/c/charging_capacitor.c3`](../../../c3/c/charging_capacitor.c3) |
| C++ | [`cpp/c/charging_capacitor.cpp`](../../../cpp/c/charging_capacitor.cpp) |
| Elisa | [`elisa/c/charging_capacitor.elisa`](../../../elisa/c/charging_capacitor.elisa) |
| Nim | [`nim/c/charging_capacitor.nim`](../../../nim/c/charging_capacitor.nim) |
| Odin | [`odin/c/charging_capacitor.odin`](../../../odin/c/charging_capacitor.odin) |
| Rust | [`rust/c/charging_capacitor.rs`](../../../rust/c/charging_capacitor.rs) |
| V | [`v/c/charging_capacitor.v`](../../../v/c/charging_capacitor.v) |
| Zig | [`zig/c/charging_capacitor.zig`](../../../zig/c/charging_capacitor.zig) |

## Pinned source

- [TheAlgorithms/Python `charging_capacitor.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/charging_capacitor.py)
