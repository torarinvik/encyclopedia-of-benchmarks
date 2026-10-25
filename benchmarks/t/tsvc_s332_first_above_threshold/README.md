# TSVC s332 first above threshold

This package is a bounded, clean-room profile of TSVC `s332` in the
`Searching-dbl` family. It scans a vector in ascending order, stops at the
first value strictly greater than a caller-supplied threshold, and reports
that zero-based index and value. If no element qualifies, it reports the
source's initialized sentinels `index=-2` and `value=-1`.

This differs from s331's full scan for the last negative element. s332 uses a
strict threshold predicate and a `goto` out of the scan at the first match;
an immediate match and a match at the tail therefore exercise different
amounts of search work.

## Contract

The exported symbol is `tsvc_s332_first_above_threshold`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, threshold, values[n]]`, with `n` in `1..256`.
- The threshold and each value are in `[-1,000,000,1,000,000]`. These
  integer-valued inputs are exactly comparable in the source's binary64
  `TYPE` profile.
- Scan in ascending order and stop on the first `values[i] > threshold`.
- Output `[i, values[i]]` as little-endian signed i64 values; return `2`. If
  no match exists, output `[-2,-1]`, preserving the source's initialized
  `index` and `value` sentinels.
- Malformed input returns `-1`; null output or capacity below 16 bytes returns
  `-2` without writes. Input is unchanged.

The source prints the `value` variable as its benchmark checksum. This
contract also emits the source's internal `index` so fixtures can verify the
early-exit position directly. The upstream timing repetitions are represented
as one bounded search call because the searched array and threshold are
unchanged between repetitions.

## Source and rights

The behavior reference is `s332` at lines 3933–3966 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3933),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its initialization is at lines
610–612. The `Searching-dbl` launcher supplies `80000 14` and calls s332 with
the setup threshold 1.0. TSVC's upstream README attributes the suite to Maleki
et al., *An Evaluation of Vectorizing Compilers*, PACT 2011,
DOI 10.1109/PACT.2011.68.

No explicit license grant was found in the pinned TSVC materials reviewed.
These ports independently implement the bounded search and reuse no upstream
source code or comments. No upstream license or endorsement is claimed; see
[`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s332_first_above_threshold_oracle.py`](../../tsvc_s332_first_above_threshold_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s332_first_above_threshold.c`](../../../c/t/tsvc_s332_first_above_threshold.c) |
| C3 | [`tsvc_s332_first_above_threshold.c3`](../../../c3/t/tsvc_s332_first_above_threshold.c3) |
| C++ | [`tsvc_s332_first_above_threshold.cpp`](../../../cpp/t/tsvc_s332_first_above_threshold.cpp) |
| Elisa | [`tsvc_s332_first_above_threshold.elisa`](../../../elisa/t/tsvc_s332_first_above_threshold.elisa) |
| Nim | [`tsvc_s332_first_above_threshold.nim`](../../../nim/t/tsvc_s332_first_above_threshold.nim) |
| Odin | [`tsvc_s332_first_above_threshold.odin`](../../../odin/t/tsvc_s332_first_above_threshold.odin) |
| Rust | [`tsvc_s332_first_above_threshold.rs`](../../../rust/t/tsvc_s332_first_above_threshold.rs) |
| V | [`tsvc_s332_first_above_threshold.v`](../../../v/t/tsvc_s332_first_above_threshold.v) |
| Zig | [`tsvc_s332_first_above_threshold.zig`](../../../zig/t/tsvc_s332_first_above_threshold.zig) |
