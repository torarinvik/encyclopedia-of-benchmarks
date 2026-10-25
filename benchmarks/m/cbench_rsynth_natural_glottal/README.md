# RSynth natural glottal-source sample

This package profiles one bounded sample of RSynth's natural glottal source. It models the source's `natural_source(nper)` recurrence after the pitch-synchronous reset initializes `natglot_a` and `natglot_b`. A requested sample is computed by replaying the recurrence from the start of one isolated pitch period; this avoids hidden state across calls while preserving the selected source sample.

## Contract

ABI: `float64_slice_io`; exported symbol: `cbench_rsynth_natural_glottal_sample`.

Input is `[nopen, sample_index]`, encoded as finite integral binary64 values. `nopen` is 40..263, matching the supported `natglot` table; `sample_index` is 0..299. Output contains exactly one binary64 value. For `sample_index >= nopen`, the source's closed-glottis branch returns zero. Otherwise initialize `b = trunc(1,920,000 / nopen²)` from the source's table, `a = f32(f32(b*nopen)*0.333)`, and `vwave = f32(0)`. For each open-phase sample through the selected index, update `a = f32(a-b)` and `vwave=f32(vwave+a)`; the selected output is `f32(vwave*0.028)`, promoted to binary64. Every intermediate follows the pinned C `float` operation boundaries. Input length must be exactly two; malformed input returns `-1`, and null/short output returns `-2` without writes.

This is only the natural glottal excitation component. The impulsive source, resonator, formant filters, phoneme dictionary, and full text-to-speech pipeline are excluded.

## Provenance and rights

- Repository and pin: [`lac-dcc/Benchmarks@5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38).
- Launcher: [`cBench/office_rsynth/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_rsynth/src/info.sh).
- Kernel: [`cBench/office_rsynth/src/nsynth.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_rsynth/src/nsynth.c), `natural_source` and `pitch_synch_par_reset`.
- The package-level [`LICENSE`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_rsynth/LICENSE) identifies the software as public domain from Carnegie Mellon University and flags certain dictionary files as separately restricted. This package uses no dictionary, phone list, or other speech data; the notice is retained in [`LICENSE.txt`](LICENSE.txt). The ports are clean-room implementations and contain no copied source or tables.

The independent oracle is [`cbench_rsynth_natural_glottal_oracle.py`](../../cbench_rsynth_natural_glottal_oracle.py); workload fixtures are in [`workload.json`](workload.json). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/m/cbench_rsynth_natural_glottal.c`](../../../c/m/cbench_rsynth_natural_glottal.c)
- C3: [`c3/m/cbench_rsynth_natural_glottal.c3`](../../../c3/m/cbench_rsynth_natural_glottal.c3)
- C++: [`cpp/m/cbench_rsynth_natural_glottal.cpp`](../../../cpp/m/cbench_rsynth_natural_glottal.cpp)
- Elisa: [`elisa/m/cbench_rsynth_natural_glottal.elisa`](../../../elisa/m/cbench_rsynth_natural_glottal.elisa)
- Nim: [`nim/m/cbench_rsynth_natural_glottal.nim`](../../../nim/m/cbench_rsynth_natural_glottal.nim)
- Odin: [`odin/m/cbench_rsynth_natural_glottal.odin`](../../../odin/m/cbench_rsynth_natural_glottal.odin)
- Rust: [`rust/m/cbench_rsynth_natural_glottal.rs`](../../../rust/m/cbench_rsynth_natural_glottal.rs)
- V: [`v/m/cbench_rsynth_natural_glottal.v`](../../../v/m/cbench_rsynth_natural_glottal.v)
- Zig: [`zig/m/cbench_rsynth_natural_glottal.zig`](../../../zig/m/cbench_rsynth_natural_glottal.zig)
