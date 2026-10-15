# Faraday–Lenz Law

## Contract

Compute the induced electromotive force from the change in magnetic flux. The input is `[final_flux_milliweber, initial_flux_milliweber, interval_milliseconds]`. Flux is represented in 0.001 Wb increments, and time in 0.001 second increments, so dividing their difference gives volts. Both flux values must be in `[-1,000,000,000, 1,000,000,000]` fixed-point units; the time interval must be in `[1, 1,000,000,000]` units.

The output is the induced voltage in decivolts: `-10 * (final_flux - initial_flux) / interval`, rounded to nearest with ties to even. Integer arithmetic defines the result exactly across platforms. Invalid inputs return the signed 64-bit minimum sentinel. The bounds keep all intermediate values in signed 64-bit range.

The pinned Python source computes `round(-(final_flux - initial_flux) / time_interval, 1)` and rejects negative intervals. This contract represents its inputs and one-decimal result in fixed-point integers and excludes zero intervals, which would divide by zero.

## Workload and verification

[`workload.json`](workload.json) includes both flux-change directions, unchanged flux, half-even ties of both signs, interval bounds, large flux changes, and invalid input. The checker-only verifier checks 1,621 deterministic cases in all nine languages and does not run the timed benchmark workload:

```sh
python3 benchmarks/verify_faraday_lenz_law.py
```

Pass `--elisa-compiler /path/to/elisac` if the Elisa compiler is not available under the default executable name.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/f/faraday_lenz_law.c](../../../c/f/faraday_lenz_law.c) |
| C3 | [c3/f/faraday_lenz_law.c3](../../../c3/f/faraday_lenz_law.c3) |
| C++ | [cpp/f/faraday_lenz_law.cpp](../../../cpp/f/faraday_lenz_law.cpp) |
| Elisa | [elisa/f/faraday_lenz_law.elisa](../../../elisa/f/faraday_lenz_law.elisa) |
| Nim | [nim/f/faraday_lenz_law.nim](../../../nim/f/faraday_lenz_law.nim) |
| Odin | [odin/f/faraday_lenz_law.odin](../../../odin/f/faraday_lenz_law.odin) |
| Rust | [rust/f/faraday_lenz_law.rs](../../../rust/f/faraday_lenz_law.rs) |
| V | [v/f/faraday_lenz_law.v](../../../v/f/faraday_lenz_law.v) |
| Zig | [zig/f/faraday_lenz_law.zig](../../../zig/f/faraday_lenz_law.zig) |

## TheAlgorithms reference

- [Python `faraday_lenz_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/faraday_lenz_law.py)
