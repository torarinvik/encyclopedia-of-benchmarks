# Corrected HyperLogLog estimate

This in-progress profile extends the fixed 16-bucket, supplied-32-bit-hash
[`hyperloglog_raw_estimate`](../hyperloglog_raw_estimate/README.md) core with
the small- and large-range corrections in the original HyperLogLog program.
It measures the complete estimate path separately from the raw-register
profile; it does not implement hash generation or HyperLogLog++.

## Draft contract

The `i64_array_bytes_output` input is `[n,hash0,...,hash(n-1)]`, with
`0 <= n <= 128`, exact length `n+1`, and each hash in `[0,2^32-1]`.
Malformed input or a null input returns `-1`. The maximum valid and parseable
frames contain 129 and 130 i64 words. Hashes are replayed as supplied; the
caller is responsible for the distribution of the hash source.

Build 16 registers using the high four hash bits as bucket index and the
remaining 28 bits for a leading-zero rank in `1..29`. Calculate the raw
estimate `E = (0.673 * 16 * 16) / sum(2^-R[j])` using all 16 registers,
including zeros, and count the zero registers `V`. Apply exactly one branch:

* If `E <= 40` and `V > 0`, use `16 * ln(16/V)`.
* Otherwise, if `E <= 2^32/30`, use `E`.
* Otherwise, if `E < 2^32`, use `-2^32 * ln(1-E/2^32)`.
* If `E >= 2^32`, return `-3` without output: the logarithm's argument is
  nonpositive and the correction has no finite real value.

The estimate is one IEEE binary64 value encoded little-endian; success returns
8. A null or shorter-than-eight-byte output returns `-2` without writes.
Input and saturation errors take precedence over output errors. Comparison of
successful results uses absolute tolerance `1e-8` and relative tolerance
`1e-12`; this permits ordinary libm rounding differences. Runtime is O(n+16)
and register storage O(16). This is a bounded deterministic replay of the
paper's 32-bit estimator, not an accuracy guarantee for supplied hash tapes.
The scaled register sum is an integer; in the finite large-range branch it is
at least 22, so `E/2^32 <= 21.536/22`. This keeps the logarithm's argument
away from zero even when a port uses `ln(1-x)` instead of `log1p(-x)`.

Source: Flajolet, Fusy, Gandouet and Meunier, *HyperLogLog: the analysis of a
near-optimal cardinality estimation algorithm* (2007), [original paper](https://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf),
Figure 3. Mathematical method only; no source prose, examples, or code copied.
Primary and high-precision independent references and ten language drafts
are present.

| Language | Draft port |
| --- | --- |
| C | [C](../../../c/h/hyperloglog_corrected_estimate.c) |
| C3 | [C3](../../../c3/h/hyperloglog_corrected_estimate.c3) |
| C++ | [C++](../../../cpp/h/hyperloglog_corrected_estimate.cpp) |
| Elisa | [Elisa](../../../elisa/h/hyperloglog_corrected_estimate.elisa) |
| Mojo | [Mojo](../../../mojo/h/hyperloglog_corrected_estimate.mojo) |
| Nim | [Nim](../../../nim/h/hyperloglog_corrected_estimate.nim) |
| Odin | [Odin](../../../odin/h/hyperloglog_corrected_estimate.odin) |
| Rust | [Rust](../../../rust/h/hyperloglog_corrected_estimate.rs) |
| V | [V](../../../v/h/hyperloglog_corrected_estimate.v) |
| Zig | [Zig](../../../zig/h/hyperloglog_corrected_estimate.zig) |

The workload specifies empty and small streams, uncorrected intermediate
estimates, large-range correction, saturation, and ABI error precedence. The
byte-output runner and verifier are wired with the stated tolerance and `-3`
saturation result; static review remains in progress. Nothing has been executed.
