# TSVC s322 second-order recurrence

This package is a bounded clean-room profile of TSVC `s322` from the
`Recurrences-dbl` launcher family. It applies one ascending in-place sweep:

```text
a[i] = a[i] + a[i - 1] * b[i] + a[i - 2] * c[i]   for i = 2 .. n-1
```

Both lag taps are used, with independent per-index coefficients. The update
order matters because each step reads the values already produced at earlier
indices. The benchmark returns the complete final A vector. It is distinct
from the first-order `s321` recurrence and the coupled two-vector `s323`
update, as well as from the repository's matrix-based `linear_recurrence_matrix`
algorithm.

## Contract

The exported symbol is `tsvc_s322_second_order_recurrence`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, a[n], b[n], c[n]]`, with `n` in `2..64`.
- Every initial A, B, and C value is in `{-1, 0, 1}`.
- For ascending `i` from 2 through `n-1`, update A using the recurrence above.
- The input remains unchanged; output the final A as little-endian signed
  i64 values and return `n`.
- Output capacity must be at least `8*n` bytes. Invalid input returns `-1`;
  null output or insufficient capacity returns `-2`. Errors write no output.

The coefficient and length limits keep the arithmetic exact in the source
binary64 profile and safely within signed i64. With unit-bounded initial values
and coefficients, the absolute value at index `i` is bounded by
`2*F(i+1)-1` (with `F(1)=F(2)=1`); at the maximum final index 63, this is
21,220,419,715,445, below the binary64 exact-integer limit `2^53`.

## Source and rights

The behavior reference is `s322` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3837)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/Recurrences-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Recurrences-dbl/tsc.c),
which selects `TYPE double` and the recurrence codelets. The source initializes
A to one and B/C to zero; this bounded profile accepts caller-supplied values
so the two-lag recurrence is observable. The TSVC source comments attribute
its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded loop
contract and reuse no upstream source code or comments; no upstream license or
endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and fixed cases are
[`tsvc_s322_second_order_recurrence_oracle.py`](../../tsvc_s322_second_order_recurrence_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s322_second_order_recurrence.c`](../../../c/t/tsvc_s322_second_order_recurrence.c) |
| C3 | [`tsvc_s322_second_order_recurrence.c3`](../../../c3/t/tsvc_s322_second_order_recurrence.c3) |
| C++ | [`tsvc_s322_second_order_recurrence.cpp`](../../../cpp/t/tsvc_s322_second_order_recurrence.cpp) |
| Elisa | [`tsvc_s322_second_order_recurrence.elisa`](../../../elisa/t/tsvc_s322_second_order_recurrence.elisa) |
| Nim | [`tsvc_s322_second_order_recurrence.nim`](../../../nim/t/tsvc_s322_second_order_recurrence.nim) |
| Odin | [`tsvc_s322_second_order_recurrence.odin`](../../../odin/t/tsvc_s322_second_order_recurrence.odin) |
| Rust | [`tsvc_s322_second_order_recurrence.rs`](../../../rust/t/tsvc_s322_second_order_recurrence.rs) |
| V | [`tsvc_s322_second_order_recurrence.v`](../../../v/t/tsvc_s322_second_order_recurrence.v) |
| Zig | [`tsvc_s322_second_order_recurrence.zig`](../../../zig/t/tsvc_s322_second_order_recurrence.zig) |
