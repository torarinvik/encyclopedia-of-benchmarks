# TSVC s423 offset-64 anti-dependence sweep

This clean-room profile captures TSVC Equivalencing `s423`. The source views
`array[64..]` through `xx`, initializes that view to one, then sweeps upward
and writes `array[i+1] = xx[i] + A[i]`. Because each write trails the source
view by 63 positions, a location is read before the loop overwrites it; this
is an anti-dependence, unlike s424's writes that feed later reads. The source
finally sums the updated base prefix `array[0..n-1]`.

## Contract

The exported symbol is `tsvc_s423_antidependence_offset64`, using the
`i64_array_scalar` ABI.

- Input: `[n, A[n], X_prefix[64]]`, with `65 <= n <= 128`; values are integers
  in `[0,2]`.
- Construct a backing array of length `n+64`; copy the 64-value prefix and
  initialize `X[64..n+63]` to one, as the source does for its `xx` view.
- For `i=0..n-2` in ascending order assign `X[i+1] = X[i+64] + A[i]`.
  Return the sum of `X[0..n-1]` after that one sweep. Input remains unchanged.
- The valid scalar result is nonnegative and at most 383. Malformed input or
  null input returns `-1`.

The upstream launcher repeats the loop for timing. This profile makes one
pass explicit and omits dummy calls and timing scaffolding. The bounded
dimensions retain the initialized suffix and alias anti-dependence while
keeping all additions exact in the source's float and double variants.

## Source and rights

Source: `s423` at lines 4503–4531 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4503),
pinned LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; the double and float launchers
are `TSVC/Equivalencing-dbl/info.sh` and `TSVC/Equivalencing-flt/info.sh`.
No explicit redistribution grant was found in the reviewed TSVC materials;
the ports are clean-room. See [LICENSE.txt](LICENSE.txt).

Cases are in [workload.json](workload.json), with the independent oracle at
[`tsvc_s423_antidependence_offset64_oracle.py`](../../tsvc_s423_antidependence_offset64_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s423_antidependence_offset64.c](../../../c/t/tsvc_s423_antidependence_offset64.c) |
| C3 | [tsvc_s423_antidependence_offset64.c3](../../../c3/t/tsvc_s423_antidependence_offset64.c3) |
| C++ | [tsvc_s423_antidependence_offset64.cpp](../../../cpp/t/tsvc_s423_antidependence_offset64.cpp) |
| Elisa | [tsvc_s423_antidependence_offset64.elisa](../../../elisa/t/tsvc_s423_antidependence_offset64.elisa) |
| Nim | [tsvc_s423_antidependence_offset64.nim](../../../nim/t/tsvc_s423_antidependence_offset64.nim) |
| Odin | [tsvc_s423_antidependence_offset64.odin](../../../odin/t/tsvc_s423_antidependence_offset64.odin) |
| Rust | [tsvc_s423_antidependence_offset64.rs](../../../rust/t/tsvc_s423_antidependence_offset64.rs) |
| V | [tsvc_s423_antidependence_offset64.v](../../../v/t/tsvc_s423_antidependence_offset64.v) |
| Zig | [tsvc_s423_antidependence_offset64.zig](../../../zig/t/tsvc_s423_antidependence_offset64.zig) |
