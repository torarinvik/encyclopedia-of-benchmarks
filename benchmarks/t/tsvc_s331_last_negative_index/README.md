# TSVC s331 last-negative scan

This package implements the Searching-dbl s331 codelet as a bounded full scan. It visits every element in ascending order and records the one-based position of each negative value, leaving the final matching position as its result. This is distinct from ordinary linear search, which stops at the first equality match; TSVC s332's first-threshold-match variant is not included because it uses that same early-exit search pattern.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `tsvc_s331_last_negative_index`.
- Input is `[n, values[0], ..., values[n-1]]`, where `1 <= n <= 256` and each value is in `[-1,000,000, 1,000,000]`.
- Scan values from index zero to `n-1`. Whenever `values[i] < 0`, replace the result with `i+1`. Return zero when no value is negative; otherwise return the one-based position of the last negative value. The one-based result matches the source's `temp = j+1` observable output.
- Malformed framing or values return `-1`.

The pinned launcher is `TSVC/Searching-dbl/info.sh`, with `RUN_OPTIONS="80000 14"`. Its `s331` initializes a harmonic positive array and then sets the final element to `-1`; the workload includes that source-shaped case plus varied bounded arrays to exercise the full scan and last-match behavior. The package replaces the timing repetition with a caller-provided bounded vector.

## Source and rights

The source is pinned to LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`: [`TSVC/Searching-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Searching-dbl/info.sh) selects [`TSVC/Searching-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Searching-dbl/tsc.c), which includes [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc). The relevant codelet is `s331` at lines 3893–3921; its default initialization is at lines 607–609. The launcher selects `double` and passes `80000 14`. The upstream README attributes the suite to Maleki et al., “An Evaluation of Vectorizing Compilers,” PACT 2011, DOI 10.1109/PACT.2011.68.

No explicit upstream license grant was found in the pinned TSVC materials reviewed. The ports are clean-room implementations and make no upstream license claim; see [`LICENSE.txt`](LICENSE.txt). The independent oracle and static cases are [`benchmarks/tsvc_s331_last_negative_index_oracle.py`](../../tsvc_s331_last_negative_index_oracle.py) and [`workload.json`](workload.json).

## Ports

Ports are provided in `c/t`, `c3/t`, `cpp/t`, `elisa/t`, `nim/t`, `odin/t`, `rust/t`, `v/t`, and `zig/t`.
