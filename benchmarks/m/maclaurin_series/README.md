# Maclaurin Sine and Cosine Series

This benchmark follows the pinned Python implementation's Maclaurin approximations for sine and cosine in radians, including its period reduction and term-by-term summation order.

## Contract

- The `i64_array_float64` ABI supplies exactly `[mode, theta, accuracy]` as signed 64-bit integers. `mode=0` selects sine and `mode=1` selects cosine. Require `theta` in `[-10,10]` and `accuracy` in `[1,30]`.
- Before summing, preserve the source reduction: `div = floor(theta / (2*pi))`, then `theta = theta - 2*div*pi`. The source uses Python floor division; over this bounded domain, `floor` of the binary64 quotient gives the same reduction.
- Starting with sum zero, add terms in increasing `r` order. Sine uses `(-1)^r * theta^(2*r+1) / factorial(2*r+1)`; cosine uses `(-1)^r * theta^(2*r) / factorial(2*r)`. `accuracy` is the number of terms, not a degree or error tolerance. Results use relative and absolute tolerance `1e-12`.
- The bounds keep powers and factorials finite and make the source's floor based reduction portable. Invalid layout, mode, or values return `-1e300`.

This is separate from `sin_degrees`, which reduces degrees, uses 18 fixed sine terms, and rounds to 10 decimal places, and `sin_radians`, which uses a Bhaskara style cosine approximation. This package retains the source's selectable sine/cosine series and accuracy argument.

## Source

- [TheAlgorithms/Python `maths/maclaurin_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/maclaurin_series.py)

## Workload and integration

[`workload.json`](workload.json) covers both modes, zero and signed angles, a full default-accuracy sample, a short truncation, both accuracy limits, and invalid inputs. The shared runner validates cases against [`maclaurin_series_oracle.py`](../../maclaurin_series_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/maclaurin_series.c`](../../../c/m/maclaurin_series.c) |
| C3 | [`c3/m/maclaurin_series.c3`](../../../c3/m/maclaurin_series.c3) |
| C++ | [`cpp/m/maclaurin_series.cpp`](../../../cpp/m/maclaurin_series.cpp) |
| Elisa | [`elisa/m/maclaurin_series.elisa`](../../../elisa/m/maclaurin_series.elisa) |
| Nim | [`nim/m/maclaurin_series.nim`](../../../nim/m/maclaurin_series.nim) |
| Odin | [`odin/m/maclaurin_series.odin`](../../../odin/m/maclaurin_series.odin) |
| Rust | [`rust/m/maclaurin_series.rs`](../../../rust/m/maclaurin_series.rs) |
| V | [`v/m/maclaurin_series.v`](../../../v/m/maclaurin_series.v) |
| Zig | [`zig/m/maclaurin_series.zig`](../../../zig/m/maclaurin_series.zig) |

Build and record an implementation with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm maclaurin_series --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/maclaurin_series/rust/build.json
```
