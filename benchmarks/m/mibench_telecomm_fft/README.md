# MiBench telecomm-FFT: bounded `fft_float` stage

This package isolates Don Cross's `fft_float` radix-2 complex FFT kernel from the pinned MiBench `telecomm-FFT` entry. The full launcher creates a deterministic mixture of sine and cosine waves (default: 8 waves and 32,768 samples), invokes an inverse transform, and prints two float arrays. This package exposes the FFT kernel with a bounded caller-provided complex vector; signal generation, command-line parsing, the full 32,768-point run, and source `printf` formatting are outside this contract. The LAC-DCC crosswalk therefore marks this entry **partial/related**.

## Pinned source and license

All sources below are pinned to commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38):

- [`fourierf.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/fourierf.c): `fft_float` kernel.
- [`fftmisc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/fftmisc.c): power-of-two validation and bit-reversal helpers.
- [`fourier.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/fourier.h) and [`ddcmath.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/ddcmath.h): interface and π constant.
- [`main.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/main.c) and [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/info.sh): launcher waveform generator and default invocation.
- Pinned [`README`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/README): launcher profile and redistribution notice.

The pinned notice calls the source public domain and permits giving away copies under stated conditions: do not charge for the source (apart from reasonable duplication/postage costs), retain Don Cross's name, email, URL and the notice, and add attribution plus a description to modified source. The full notice is bundled as [`LICENSE.txt`](LICENSE.txt). Each port retains Don Cross's attribution and records the bounded ABI adaptation. These notice conditions are included with the package.

## Contract

The exported function is `mibench_telecomm_fft` in the `float64_slice_io` ABI:

```c
int64_t mibench_telecomm_fft(const double *input, size_t input_length,
                             double *output, size_t output_capacity);
```

Input is `[n, inverse, real samples..., imaginary samples...]`. `n` must be a power of two in `[2,16]`; `inverse` must be exactly `0` (forward) or `1` (inverse); there must be exactly `2+2*n` finite values; and each sample magnitude must be at most 8. The adapter stores input and work arrays as binary32, matching the source kernel, while its twiddle recurrence uses binary64 as in `fourierf.c`.

Output is interleaved natural-order `[real_0, imag_0, ..., real_(n-1), imag_(n-1)]`. Components are the source's binary32 results widened to binary64 for the suite ABI. The inverse transform divides each output component by `n`, with binary32 rounding after the division.

| Result | Meaning |
|---:|---|
| `2*n` | Success; that many output elements were written. |
| `-1` | Invalid pointer framing, length, transform size/flag, nonfinite sample, or sample outside the bound. |
| `-2` | Null output or capacity smaller than `2*n`. |

The implementation validates and stages the complete result before writing output. On errors it leaves output untouched. `workload.json` contains forward, inverse, maximum-size zero input, invalid-frame, and short-capacity fixtures. The independent oracle models the source bit-reversal and twiddle recurrence and rounds each work-array store to binary32.

## Ports

| Language | Port |
|---|---|
| C | [`c/m/mibench_telecomm_fft.c`](../../../c/m/mibench_telecomm_fft.c) |
| C3 | [`c3/m/mibench_telecomm_fft.c3`](../../../c3/m/mibench_telecomm_fft.c3) |
| C++ | [`cpp/m/mibench_telecomm_fft.cpp`](../../../cpp/m/mibench_telecomm_fft.cpp) |
| Elisa | [`elisa/m/mibench_telecomm_fft.elisa`](../../../elisa/m/mibench_telecomm_fft.elisa) |
| Nim | [`nim/m/mibench_telecomm_fft.nim`](../../../nim/m/mibench_telecomm_fft.nim) |
| Odin | [`odin/m/mibench_telecomm_fft.odin`](../../../odin/m/mibench_telecomm_fft.odin) |
| Rust | [`rust/m/mibench_telecomm_fft.rs`](../../../rust/m/mibench_telecomm_fft.rs) |
| V | [`v/m/mibench_telecomm_fft.v`](../../../v/m/mibench_telecomm_fft.v) |
| Zig | [`zig/m/mibench_telecomm_fft.zig`](../../../zig/m/mibench_telecomm_fft.zig) |
