# TSVC s424 alias-overlap feedback sweep

`tsvc_s424_alias_overlap_feedback` is a bounded, clean-room profile of the TSVC Equivalencing `s424` codelet. The source assigns `xx = array + 63`, then sweeps upward while writing `xx[i+1]`. In backing-array coordinates this is `array[i+64] = array[i] + a[i]`. Once `i` reaches 64, the read observes a value written earlier in the same sweep. This alias-induced feedback is the core operation.

## Contract

The exported symbol is `tsvc_s424_alias_overlap_feedback` and uses the `i64_array_scalar` ABI.

- Input: `[n, A[n], X_prefix[63]]`.
- `n` is in `66..192`; exact input length is `n+64`.
- Every A and prefix value is in `[0,10]`, interpreted as an integer-valued source `double` or `float`. This keeps the valid checksum nonnegative and separate from the invalid-input sentinel.
- Before the sweep, all backing-array positions from 63 through `n+62` inclusive are zero, matching the source's `set1d(xx, 0., 1)` initialization. The 63 explicit `X_prefix` values represent backing-array positions 0 through 62.
- Run one ascending sweep for `i=0..n-2`: `X[i+64] = X[i] + A[i]`. Do not reorder this loop; writes feed later reads at the 64-element displacement.
- Return the source-observed checksum `X[63] + ... + X[n+62]`, corresponding to the source's final sum over `xx[0..n-1]`. The bounded maximum dependency chain has three additions, so values are within `[0,40]` and the checksum within `[0,7680]`, exact in both source precisions.
- Invalid or null input returns `-1`. The profile uses local copies and leaves input unchanged.

The profile omits the timing and repeated-pass wrapper while preserving the `s424` storage overlap, initialization of the aliased view, ascending update order, and observed checksum. It accepts explicit A and prefix values so each call is deterministic.

The workload contains a hand-derived minimum-size case where the first write to `X[64]` is read at iteration 64 and changes the final checksum. The independent oracle reproduces the backing-array view and in-place sweep.

## Source and rights

The codelet is `s424` at lines 4317–4345 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by the double-precision [`Equivalencing-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Equivalencing-dbl/tsc.c) and float [`Equivalencing-flt/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Equivalencing-flt/tsc.c), at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launchers use `3125 14` (double) and `3125 5` (float). The TSVC source comments attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports are clean-room implementations of the bounded operation, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s424_alias_overlap_feedback_oracle.py`](../../tsvc_s424_alias_overlap_feedback_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s424_alias_overlap_feedback.c`](../../../c/t/tsvc_s424_alias_overlap_feedback.c) |
| C3 | [`tsvc_s424_alias_overlap_feedback.c3`](../../../c3/t/tsvc_s424_alias_overlap_feedback.c3) |
| C++ | [`tsvc_s424_alias_overlap_feedback.cpp`](../../../cpp/t/tsvc_s424_alias_overlap_feedback.cpp) |
| Elisa | [`tsvc_s424_alias_overlap_feedback.elisa`](../../../elisa/t/tsvc_s424_alias_overlap_feedback.elisa) |
| Nim | [`tsvc_s424_alias_overlap_feedback.nim`](../../../nim/t/tsvc_s424_alias_overlap_feedback.nim) |
| Odin | [`tsvc_s424_alias_overlap_feedback.odin`](../../../odin/t/tsvc_s424_alias_overlap_feedback.odin) |
| Rust | [`tsvc_s424_alias_overlap_feedback.rs`](../../../rust/t/tsvc_s424_alias_overlap_feedback.rs) |
| V | [`tsvc_s424_alias_overlap_feedback.v`](../../../v/t/tsvc_s424_alias_overlap_feedback.v) |
| Zig | [`tsvc_s424_alias_overlap_feedback.zig`](../../../zig/t/tsvc_s424_alias_overlap_feedback.zig) |
