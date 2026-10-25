# TSVC s323 coupled recurrence

This package is a bounded clean-room profile of TSVC `s323` from the
`Recurrences-dbl` launcher family. It performs one ascending coupled sweep:

```text
a[i] = b[i - 1] + c[i] * d[i]
b[i] = a[i] + c[i] * e[i]
```

Both statements execute in order for each `i = 1 .. n-1`; the B update reads
the newly assigned A value, and the next iteration reads the newly assigned
previous B value. Index zero is preserved from the input. The result is A
followed by B. This is distinct from `s211`: although that codelet also
updates A and B in a loop, its B update reads the next old B element, while
`s323` computes B from the current newly updated A and feeds that B into the
next iteration. It also differs from the one- and two-lag scalar recurrences
in `s321` and `s322`.

## Contract

The exported symbol is `tsvc_s323_coupled_recurrence`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, a[n], b[n], c[n], d[n], e[n]]`, with `n` in `2..64`.
- Every input value is in `{-1, 0, 1}`.
- For ascending `i` from 1 through `n-1`, apply the two assignments above in
  order.
- Input is unchanged. Output final A followed by final B as little-endian
  signed i64 values and return `2*n`.
- Output capacity must be at least `16*n` bytes. Invalid input returns `-1`;
  null output or insufficient capacity returns `-2`. Errors write no output.

With unit-bounded inputs, `|b[i]| <= 1 + 2*i` and `|a[i]| <= 2*i` for `i>0`;
the maximum profile values are at most 127 in magnitude. This keeps the
integer workload exact in the source binary64 profile and safely within i64.

## Source and rights

The behavior reference is `s323` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3863)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/Recurrences-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Recurrences-dbl/tsc.c),
which selects `TYPE double` and the recurrence codelets. The source initializes
A and B to one; this bounded profile accepts caller-supplied values so the
ordered coupled recurrence is observable. The TSVC source comments attribute
its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded loop
contract and reuse no upstream source code or comments; no upstream license or
endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and fixed cases are
[`tsvc_s323_coupled_recurrence_oracle.py`](../../tsvc_s323_coupled_recurrence_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s323_coupled_recurrence.c`](../../../c/t/tsvc_s323_coupled_recurrence.c) |
| C3 | [`tsvc_s323_coupled_recurrence.c3`](../../../c3/t/tsvc_s323_coupled_recurrence.c3) |
| C++ | [`tsvc_s323_coupled_recurrence.cpp`](../../../cpp/t/tsvc_s323_coupled_recurrence.cpp) |
| Elisa | [`tsvc_s323_coupled_recurrence.elisa`](../../../elisa/t/tsvc_s323_coupled_recurrence.elisa) |
| Nim | [`tsvc_s323_coupled_recurrence.nim`](../../../nim/t/tsvc_s323_coupled_recurrence.nim) |
| Odin | [`tsvc_s323_coupled_recurrence.odin`](../../../odin/t/tsvc_s323_coupled_recurrence.odin) |
| Rust | [`tsvc_s323_coupled_recurrence.rs`](../../../rust/t/tsvc_s323_coupled_recurrence.rs) |
| V | [`tsvc_s323_coupled_recurrence.v`](../../../v/t/tsvc_s323_coupled_recurrence.v) |
| Zig | [`tsvc_s323_coupled_recurrence.zig`](../../../zig/t/tsvc_s323_coupled_recurrence.zig) |
