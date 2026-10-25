# TSVC s1221 lag-four additive recurrence

`tsvc_s1221_lag4_add_recurrence` is a bounded, clean-room profile of TSVC `s1221`. In ascending index order, it updates B from the value four positions earlier plus the same-position A value. This forms four independent recurrence chains, one for each index residue modulo four.

## Contract

The exported symbol is `tsvc_s1221_lag4_add_recurrence` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, A[n], B[n]]`.
- `n` is in `5..32`; exact input length is `1 + 2*n`.
- Every A and B entry is in `[-10,10]`, represented as an integer-valued source `double`. The longest recurrence path has at most seven updates, so results stay within `[-80,80]` and all operations are exact in binary64 and binary32.
- Run one ascending source-body sweep for `i=4..n-1`: `B[i]=B[i-4]+A[i]`. The first four B entries are unchanged; A is unchanged.
- Output is the complete final B vector as little-endian signed i64 values. Success returns `n` and writes `8*n` bytes. Invalid input returns `-1`; null output or capacity below `8*n` returns `-2` without writes. Maximum output capacity is 256 bytes.
- The profile omits TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the body `ntimes` times. It accepts explicit A and B arrays rather than reproducing the source's all-one A and reciprocal-square B initializer.

Fixtures cover four independent lag-four chains, signed recurrence values, a single update at the minimum dimension, malformed shape/range data, null pointers, and insufficient output capacity. The independent oracle follows the four residue-class chains, not a port of the benchmark's timing wrapper.

## Source and rights

The codelet is `s1221` at lines 1936–1957 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by the double-precision [`TSVC/LoopRestructuring-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-dbl/tsc.c) and the corresponding float [`TSVC/LoopRestructuring-flt/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-flt/tsc.c), at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launchers are [`LoopRestructuring-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-dbl/info.sh) with options `4350 14` and [`LoopRestructuring-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-flt/info.sh) with options `4350 5`. Both invoke the same source recurrence; the bounded integral domain is exact in both source precisions.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s1221_lag4_add_recurrence_oracle.py`](../../tsvc_s1221_lag4_add_recurrence_oracle.py). Suite registration is handled separately.

## Distinction from nearby recurrence kernels

The local TSVC first- and second-order recurrence packages depend on the preceding one or two entries. s1221 instead carries four independent lag-four chains, with no multiplicative coefficients and an additive forcing vector A. The implementation is also distinct from the LoopRestructuring `s221` loop, which has a lag-one B recurrence coupled to an in-place A update.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s1221_lag4_add_recurrence.c`](../../../c/t/tsvc_s1221_lag4_add_recurrence.c) |
| C3 | [`tsvc_s1221_lag4_add_recurrence.c3`](../../../c3/t/tsvc_s1221_lag4_add_recurrence.c3) |
| C++ | [`tsvc_s1221_lag4_add_recurrence.cpp`](../../../cpp/t/tsvc_s1221_lag4_add_recurrence.cpp) |
| Elisa | [`tsvc_s1221_lag4_add_recurrence.elisa`](../../../elisa/t/tsvc_s1221_lag4_add_recurrence.elisa) |
| Nim | [`tsvc_s1221_lag4_add_recurrence.nim`](../../../nim/t/tsvc_s1221_lag4_add_recurrence.nim) |
| Odin | [`tsvc_s1221_lag4_add_recurrence.odin`](../../../odin/t/tsvc_s1221_lag4_add_recurrence.odin) |
| Rust | [`tsvc_s1221_lag4_add_recurrence.rs`](../../../rust/t/tsvc_s1221_lag4_add_recurrence.rs) |
| V | [`tsvc_s1221_lag4_add_recurrence.v`](../../../v/t/tsvc_s1221_lag4_add_recurrence.v) |
| Zig | [`tsvc_s1221_lag4_add_recurrence.zig`](../../../zig/t/tsvc_s1221_lag4_add_recurrence.zig) |
