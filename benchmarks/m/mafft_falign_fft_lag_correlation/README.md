# MAFFT Falign FFT lag correlation

This package isolates the launcher-default FFT score-profile stage of MAFFT's
`Falign`. The pinned `info.sh` options do not include `-e`; `pairlocalalign.c`
therefore leaves `fftscore=1` enabled. In that path, `seq_vec_5` maps each
standard amino acid to one complex feature: population-standardized Miyata
polarity in the real component and population-standardized Miyata volume in
the imaginary component. For two single-sequence clusters with unit weights,
the code FFTs each feature sequence, multiplies the first spectrum by the
conjugate of the second, applies an inverse transform, and reorders the full
profile into source lag order.

The package returns that bounded profile before MAFFT extracts candidate
anchors. It does not run MAFFT's anchor refinement, segment sorting,
dynamic-programming alignment, multiple-sequence weighting, or FASTA driver.
The one-hot 20-channel algorithm is the alternate `-e` scoring path and is
not the operation represented here.

## Contract

The `float64_slice_io` symbol is
`mafft_falign_fft_lag_correlation(input, input_length, output,
output_capacity)`. Input is
`[first_length, second_length, first_ascii_codes..., second_ascii_codes...]`.
Both lengths are from 1 through 32. Sequences use only uppercase standard
amino acids `ARNDCQEGHILKMFPSTWYV`; each letter is its ASCII integer value
transported as an exact-integral binary64 number. The input length must equal
`2 + first_length + second_length`.

Let `n` be the smallest power of two strictly greater than the longer
sequence. The result contains `n` binary64 values. Output slot `q` represents
lag `q - n/2`; its value is the circular sum over the shared complex feature
vectors at that lag, divided by `n`. The bounded transform length is at most
64. The correlation is circular because it is the full padded FFT profile
used by `Falign` before candidate selection.

Malformed input returns `-1`. Null output or insufficient output capacity
returns `-2`; either error leaves output untouched. Successful return is `n`,
the number of scores. The independent oracle computes the same feature
correlation directly, without an FFT.

This is distinct from the repository's generic forward/inverse FFT packages:
it transforms complex amino-acid physicochemical features and combines them
into a sequence-offset score profile. It is also distinct from the
Needleman–Wunsch and Smith–Waterman packages, which perform dynamic programming
to return an alignment score or alignment.

## Provenance and rights

Pinned source is `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`:

- [`mafft/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/info.sh#L1-L10) supplies the launcher options and protein FASTA workload.
- [`mafft/pairlocalalign.c`, lines 468–484 and 557–562](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/pairlocalalign.c#L468-L562) establishes that `fftscore=1` is the default and `-e` is what disables it.
- [`mafft/Falign.c`, lines 66–79 and 923–1087](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/Falign.c#L66-L79) contains `seq_vec_5` and the FFT feature path, conjugate spectrum products, inverse transform, lag reorder, and candidate extraction.
- [`mafft/fft.c`, lines 45–117](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/fft.c#L45-L117) defines the radix-2 transform and forward normalization.
- [`mafft/fftFunctions.c`, lines 30–34](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/fftFunctions.c#L30-L34), [`mafft/miyata.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/miyata.h), and [`mafft/constants.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/constants.c) document the spectrum product, raw features, and standardization.

MAFFT's pinned [`license`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/license) contains BSD-3-Clause-style redistribution terms. The license text is retained in [`LICENSE.txt`](LICENSE.txt). These ports and the oracle are clean-room implementations of the documented operation; they do not copy or translate upstream source.

## Workload and ports

[`workload.json`](workload.json) covers self-correlation, repeated residues,
malformed inputs, unsupported residue codes, and insufficient output
capacity. The oracle is
[`benchmarks/mafft_falign_fft_lag_correlation_oracle.py`](../../mafft_falign_fft_lag_correlation_oracle.py).

| Language | Source |
| --- | --- |
| C | [`c/m/mafft_falign_fft_lag_correlation.c`](../../../c/m/mafft_falign_fft_lag_correlation.c) |
| C3 | [`c3/m/mafft_falign_fft_lag_correlation.c3`](../../../c3/m/mafft_falign_fft_lag_correlation.c3) |
| C++ | [`cpp/m/mafft_falign_fft_lag_correlation.cpp`](../../../cpp/m/mafft_falign_fft_lag_correlation.cpp) |
| Elisa | [`elisa/m/mafft_falign_fft_lag_correlation.elisa`](../../../elisa/m/mafft_falign_fft_lag_correlation.elisa) |
| Nim | [`nim/m/mafft_falign_fft_lag_correlation.nim`](../../../nim/m/mafft_falign_fft_lag_correlation.nim) |
| Odin | [`odin/m/mafft_falign_fft_lag_correlation.odin`](../../../odin/m/mafft_falign_fft_lag_correlation.odin) |
| Rust | [`rust/m/mafft_falign_fft_lag_correlation.rs`](../../../rust/m/mafft_falign_fft_lag_correlation.rs) |
| V | [`v/m/mafft_falign_fft_lag_correlation.v`](../../../v/m/mafft_falign_fft_lag_correlation.v) |
| Zig | [`zig/m/mafft_falign_fft_lag_correlation.zig`](../../../zig/m/mafft_falign_fft_lag_correlation.zig) |
