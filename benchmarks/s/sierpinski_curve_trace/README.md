# Sierpinski curve direction trace

This package records the closed Sierpinski curve from Wirth's recursive
four-orientation construction as a compact sequence of line moves. It does not
draw to a display. The move trace is the algorithm's observable result.

## Contract

- ABI: `i64_array_bytes_output`, symbol `sierpinski_curve_trace`.
- Input is exactly `[order]`, where `order` is in `0..=2`. This is Wirth's
  curve index `q`: `q=0` is the non-empty base square `S0`, while `q=1` and
  `q=2` are his first two refined curves. The maximum valid input has 1 word;
  one extra word is parseable but malformed.
- The top-level path is `A(q), direction 7, B(q), direction 5, C(q),
  direction 3, D(q), direction 1`. Direction indices are multiples of
  45 degrees. Each output byte uses its low three bits for the direction
  index; bit 3 means the line length is `2h` instead of `h`.
- The four recursively oriented pieces use the production schedule from
  Wirth §3.3. At index zero, each piece is empty. Index `q` has
  `4^(q+1)` moves, so the maximum output is 64 bytes. The fixed expansion
  stack has 64 two-byte frames plus scalar state; the workspace cap is 256
  bytes.
- Malformed or null input returns `-1` before output validation. A null output
  or insufficient capacity returns `-2` without writes. Success returns the
  number of output bytes.

The primary reference emits the four oriented procedures recursively. The
independent reference repeatedly rewrites a bounded symbol stream. Both take
O(4^(q+1)) time. The native ports use an explicit fixed expansion stack,
bounded by the workload's order limit.

## Source and duplicate review

The discovery lead is RosettaCodeData's score-28 **Sierpinski curve** title in
the pinned [`popular-tasks` revision
`1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks).
The concrete curve variant is pinned to Niklaus Wirth, *Algorithms and Data
Structures* (Oberon version), §3.3, Figures 3.5–3.6, pp. 105–107
([source PDF](https://people.inf.ethz.ch/~wirth/AD.pdf)). The source gives
the A/B/C/D recursive pieces, their 45-degree direction indices, and the
top-level closed path. The workload measures that one curve at each order.

[`sierpinski_triangle`](../sierpinski_triangle/README.md) traces repeated
triangle outlines from a pinned recursive triangle routine;
[`sierpinski_carpet`](../sierpinski_carpet/README.md) emits a raster from a
base-3 hole predicate. This package emits one closed oriented line curve using
Wirth's four-state recursion, so its core operation and output differ from
both local packages.

See [`TITLE_AUDIT.md`](TITLE_AUDIT.md) for all score-28 title dispositions.
RosettaCodeData is used as a title index only; no task wording, examples,
tests, submissions, or implementations were used. No source code, sample
figures, or prose are reproduced.

## Package files

- [`workload.json`](workload.json) pins the base curve, recursive orders,
  maximum output and ABI failure cases.
- [`primary_oracle.py`](primary_oracle.py) and
  [`independent_oracle.py`](independent_oracle.py) implement different
  constructions of the same move stream.
- [`RIGHTS.md`](RIGHTS.md), inventory files, and package-local static helpers
  track provenance and source coverage. Shared suite/catalog integration is
  root-owned.

| Language | Source |
| --- | --- |
| C | [`c/s/sierpinski_curve_trace.c`](../../../c/s/sierpinski_curve_trace.c) |
| C3 | [`c3/s/sierpinski_curve_trace.c3`](../../../c3/s/sierpinski_curve_trace.c3) |
| C++ | [`cpp/s/sierpinski_curve_trace.cpp`](../../../cpp/s/sierpinski_curve_trace.cpp) |
| Elisa | [`elisa/s/sierpinski_curve_trace.elisa`](../../../elisa/s/sierpinski_curve_trace.elisa) |
| Mojo | [`mojo/s/sierpinski_curve_trace.mojo`](../../../mojo/s/sierpinski_curve_trace.mojo) |
| Nim | [`nim/s/sierpinski_curve_trace.nim`](../../../nim/s/sierpinski_curve_trace.nim) |
| Odin | [`odin/s/sierpinski_curve_trace.odin`](../../../odin/s/sierpinski_curve_trace.odin) |
| Rust | [`rust/s/sierpinski_curve_trace.rs`](../../../rust/s/sierpinski_curve_trace.rs) |
| V | [`v/s/sierpinski_curve_trace.v`](../../../v/s/sierpinski_curve_trace.v) |
| Zig | [`zig/s/sierpinski_curve_trace.zig`](../../../zig/s/sierpinski_curve_trace.zig) |
