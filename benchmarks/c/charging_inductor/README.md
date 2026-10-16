# Charging inductor current

This benchmark ports the pinned Python RL charging formula:

```text
round(source_voltage / resistance * (1 - exp((-time * resistance) / inductance)), 3)
```

The source rejects nonpositive source voltage, resistance, and inductance. It does not reject negative time, so bounded negative-time inputs remain valid.

## Contract

The signed-i64 input is `[source_voltage_micro, resistance_micro, inductance_micro, time_micro]`. Each field represents a real-valued quantity divided by 1,000,000. Source voltage is from 0.000001 through 1,000,000 volts, resistance from 0.01 through 1,000,000,000 ohms, inductance from 0.000001 through 1,000,000 henrys, and time from -1,000,000 through 1,000,000 seconds.

The adapter also requires the computed exponential argument `(-time * resistance) / inductance` to be at most 10. This bounds negative-time growth so the exponential and rounded current remain finite and the exact binary64 rounding helper stays within its integer range. Positive times remain valid across the full stated bounds, including cases where `exp` underflows to zero. Malformed, nonpositive-component, out-of-range, or over-bound exponential inputs return `-1e300`.

The shared ABI is:

```c
double charging_inductor(const int64_t *values, size_t length);
```

[`workload.json`](workload.json) includes the three pinned examples, zero time, bounded negative time, the exponential-argument boundary, large positive time, rounding cases, and malformed inputs. The independent oracle is [`benchmarks/charging_inductor_oracle.py`](../../charging_inductor_oracle.py).

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm charging_inductor --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_float64.py \
  --build-manifest build/i64_array_float64/c/charging_inductor/rust/build.json
```

Verify the registered ports with:

```sh
python3 benchmarks/verify_charging_inductor.py --languages rust
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/c/charging_inductor.c`](../../../c/c/charging_inductor.c) |
| C3 | [`c3/c/charging_inductor.c3`](../../../c3/c/charging_inductor.c3) |
| C++ | [`cpp/c/charging_inductor.cpp`](../../../cpp/c/charging_inductor.cpp) |
| Elisa | [`elisa/c/charging_inductor.elisa`](../../../elisa/c/charging_inductor.elisa) |
| Nim | [`nim/c/charging_inductor.nim`](../../../nim/c/charging_inductor.nim) |
| Odin | [`odin/c/charging_inductor.odin`](../../../odin/c/charging_inductor.odin) |
| Rust | [`rust/c/charging_inductor.rs`](../../../rust/c/charging_inductor.rs) |
| V | [`v/c/charging_inductor.v`](../../../v/c/charging_inductor.v) |
| Zig | [`zig/c/charging_inductor.zig`](../../../zig/c/charging_inductor.zig) |

## Pinned source

- [TheAlgorithms/Python `charging_inductor.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/charging_inductor.py)
