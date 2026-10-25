# TSVC s261 shifted cross-array update

This package is a bounded, clean-room, one-sweep profile of TSVC `s261` in
the `Expansion-dbl` family. The loop visits indices from one upward. At each
index it first adds A[i] and B[i], adds the current preceding C value to A[i],
then scales C[i] by D[i]:

```text
t = A[i] + B[i]
A[i] = t + C[i-1]
t = C[i] * D[i]
C[i] = t
```

Because each C value is scaled after it has contributed to the next A update,
for i greater than one the left-neighbor read sees the preceding iteration's
new C value. A[0] and C[0] remain unchanged. This is distinct from s321's
first-order A recurrence, s322's second-order recurrence, and s323's coupled
A/B recurrence; it updates C in place while feeding its transformed value to
the following A position.

## Contract

The exported symbol is `tsvc_s261_shifted_cross_array_update`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, A[n], B[n], C[n], D[n]]`, with `n` in `2..64`.
- Every input value is in `[-2,2]`. The single-pass intermediate values are
  small exact integers in both binary64 and signed i64.
- Perform one ascending sweep for `i=1..n-1` in source statement order.
- Emit final A followed by final C as little-endian signed i64 values and
  return `2*n`. Required output capacity is `16*n` bytes.
- Malformed input returns `-1`; null output or insufficient capacity returns
  `-2` without writes. Input is unchanged.

The source timing wrapper repeats the loop and evolves its arrays; this
bounded package represents a single loop-body sweep on explicit inputs.

## Source and rights

The behavior reference is `s261` at lines 2629–2655 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2629),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Initialization is at lines
467–471. The launcher is
[`TSVC/Expansion-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c).
TSVC comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s261_shifted_cross_array_update_oracle.py`](../../tsvc_s261_shifted_cross_array_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s261_shifted_cross_array_update.c`](../../../c/t/tsvc_s261_shifted_cross_array_update.c) |
| C3 | [`tsvc_s261_shifted_cross_array_update.c3`](../../../c3/t/tsvc_s261_shifted_cross_array_update.c3) |
| C++ | [`tsvc_s261_shifted_cross_array_update.cpp`](../../../cpp/t/tsvc_s261_shifted_cross_array_update.cpp) |
| Elisa | [`tsvc_s261_shifted_cross_array_update.elisa`](../../../elisa/t/tsvc_s261_shifted_cross_array_update.elisa) |
| Nim | [`tsvc_s261_shifted_cross_array_update.nim`](../../../nim/t/tsvc_s261_shifted_cross_array_update.nim) |
| Odin | [`tsvc_s261_shifted_cross_array_update.odin`](../../../odin/t/tsvc_s261_shifted_cross_array_update.odin) |
| Rust | [`tsvc_s261_shifted_cross_array_update.rs`](../../../rust/t/tsvc_s261_shifted_cross_array_update.rs) |
| V | [`tsvc_s261_shifted_cross_array_update.v`](../../../v/t/tsvc_s261_shifted_cross_array_update.v) |
| Zig | [`tsvc_s261_shifted_cross_array_update.zig`](../../../zig/t/tsvc_s261_shifted_cross_array_update.zig) |
