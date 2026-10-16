# Butterworth audio filter coefficients

This benchmark covers all nine biquad factories in the pinned Python audio-filter module: low-pass, high-pass, band-pass, all-pass, peak, low-shelf, high-shelf, notch, and constant-peak band-pass. It returns one selected coefficient from the factory's `IIRFilter` result.

## Contract

The signed-i64 input is `[filter_kind, coefficient_index, frequency_hz, samplerate_hz, gain_milli_db, q_factor_micro]`. Filter kinds `0..8` select the variants in the order listed above. Coefficient indices `0..5` select `[a0, a1, a2, b0, b1, b2]`. The frequency is from 1 through 95,999 Hz, the samplerate from 1 through 192,000 Hz, and `2 * frequency < samplerate`. These bounds keep the benchmark on the shared valid frequency domain, including the two source factories that do not call `_validate_frequency`.

Gain is required only for peak, low-shelf, and high-shelf filters, and is encoded in milli-decibels from -60,000 through 60,000; other filter kinds require zero. A Q value of `-1` selects the source default `1 / sqrt(2)`. Otherwise `q_factor_micro` is from 1 through 10,000,000 and represents `q_factor / 1,000,000`. Malformed input returns `-1e300`, the ABI sentinel for the source's validation errors and out-of-contract parameter values.

The shared ABI is:

```c
double butterworth_filter(const int64_t *values, size_t length);
```

## Workload and verification

[`workload.json`](workload.json) covers every coefficient for all nine source variants at the pinned 1,000 Hz / 48,000 Hz examples, plus custom Q/gain settings, frequency boundaries, and malformed values. The independent formula oracle is [`benchmarks/butterworth_filter_oracle.py`](../../butterworth_filter_oracle.py).

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm butterworth_filter --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_float64.py \
  --build-manifest build/i64_array_float64/b/butterworth_filter/rust/build.json
```

Verify the registered ports with:

```sh
python3 benchmarks/verify_butterworth_filter.py --languages rust
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/butterworth_filter.c`](../../../c/b/butterworth_filter.c) |
| C3 | [`c3/b/butterworth_filter.c3`](../../../c3/b/butterworth_filter.c3) |
| C++ | [`cpp/b/butterworth_filter.cpp`](../../../cpp/b/butterworth_filter.cpp) |
| Elisa | [`elisa/b/butterworth_filter.elisa`](../../../elisa/b/butterworth_filter.elisa) |
| Nim | [`nim/b/butterworth_filter.nim`](../../../nim/b/butterworth_filter.nim) |
| Odin | [`odin/b/butterworth_filter.odin`](../../../odin/b/butterworth_filter.odin) |
| Rust | [`rust/b/butterworth_filter.rs`](../../../rust/b/butterworth_filter.rs) |
| V | [`v/b/butterworth_filter.v`](../../../v/b/butterworth_filter.v) |
| Zig | [`zig/b/butterworth_filter.zig`](../../../zig/b/butterworth_filter.zig) |

## Pinned sources

- [TheAlgorithms/Python `butterworth_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/butterworth_filter.py)
- [TheAlgorithms/Python `iir_filter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/iir_filter.py)
