# TSVC s221 partially recursive fused update

This clean-room profile captures the `s221` LoopRestructuring codelet's
ascending single-pass operation. At each index after zero, it first applies
`A[i] += C[i] * D[i]`, then updates the recurrence
`B[i] = B[i-1] + A[i] + D[i]`. The recurrence reads the newly updated A and
the previously updated B, so the source order is significant. It differs from
the single-array neighbor recurrences and from s275's independent per-column
recurrence.

## Contract

The exported function is `tsvc_s221_partial_recursive_fused_update` using the
`float64_slice_io` ABI.

- Input: `[n, A[n], B[n], C[n], D[n]]`, where `1 <= n <= 64` and all values
  are finite integer-valued binary64 values in `[-2,2]`.
- Leave A[0] and B[0] unchanged. For i=1..n-1 in ascending order, execute
  `A[i] = A[i] + C[i]*D[i]`, then `B[i] = (B[i-1] + A[i]) + D[i]`.
- Emit final A followed by final B, for `2*n` output elements. Inputs are not
  modified. The domain keeps every intermediate within 512 and exactly
  representable in binary32 and binary64.
- Malformed input returns `-1`. Null output or capacity below `2*n` returns
  `-2` after validation, with no output writes.

The upstream launcher repeats the loop for timing; this profile exposes one
loop-body pass with explicit caller state and excludes dummy-call scaffolding.

## Source and rights

Source: `s221` at lines 1992–2016 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1992),
pinned LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The double launcher is
[`TSVC/LoopRestructuring-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-dbl/info.sh);
the corresponding float launcher selects the same recurrence with binary32
`TYPE`. No explicit redistribution grant was found in the reviewed TSVC
materials. The ports are clean-room and contain no copied upstream code or
comments; see [LICENSE.txt](LICENSE.txt).

The fixed cases are in [workload.json](workload.json); the independent oracle
is [`tsvc_s221_partial_recursive_fused_update_oracle.py`](../../tsvc_s221_partial_recursive_fused_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s221_partial_recursive_fused_update.c](../../../c/t/tsvc_s221_partial_recursive_fused_update.c) |
| C3 | [tsvc_s221_partial_recursive_fused_update.c3](../../../c3/t/tsvc_s221_partial_recursive_fused_update.c3) |
| C++ | [tsvc_s221_partial_recursive_fused_update.cpp](../../../cpp/t/tsvc_s221_partial_recursive_fused_update.cpp) |
| Elisa | [tsvc_s221_partial_recursive_fused_update.elisa](../../../elisa/t/tsvc_s221_partial_recursive_fused_update.elisa) |
| Nim | [tsvc_s221_partial_recursive_fused_update.nim](../../../nim/t/tsvc_s221_partial_recursive_fused_update.nim) |
| Odin | [tsvc_s221_partial_recursive_fused_update.odin](../../../odin/t/tsvc_s221_partial_recursive_fused_update.odin) |
| Rust | [tsvc_s221_partial_recursive_fused_update.rs](../../../rust/t/tsvc_s221_partial_recursive_fused_update.rs) |
| V | [tsvc_s221_partial_recursive_fused_update.v](../../../v/t/tsvc_s221_partial_recursive_fused_update.v) |
| Zig | [tsvc_s221_partial_recursive_fused_update.zig](../../../zig/t/tsvc_s221_partial_recursive_fused_update.zig) |
