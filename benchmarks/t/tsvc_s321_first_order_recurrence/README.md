# TSVC s321 first-order recurrence

This package is a bounded clean-room profile of TSVC `s321` from the
`Recurrences-dbl` launcher family. It performs one ascending in-place sweep:

```text
a[i] = a[i] + a[i - 1] * b[i]   for i = 1 .. n-1
```

Each index uses its current A value and the already-updated previous A value.
The package returns the final A vector. It is distinct from `s322`'s
second-order recurrence, `s323`'s coupled A/B recurrence, the repository's
neighbor-update codelets, and matrix-based `linear_recurrence_matrix`: this
contract uses one previous-index A dependency with a position-specific
multiplier.

## Contract

The exported symbol is `tsvc_s321_first_order_recurrence`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, a[n], b[n]]`, with `n` in `1..64`.
- Every initial A and B value is in `{-1, 0, 1}`.
- For ascending `i` from 1 through `n-1`, update A using the recurrence above.
- Input is unchanged. Output the final A as little-endian signed i64 values
  and return `n`.
- Output capacity must be at least `8*n` bytes. Invalid input returns `-1`;
  null output or insufficient capacity returns `-2`. Errors write no output.

The coefficient and length bounds keep arithmetic exact in the source
binary64 profile and safely within signed i64: the maximum absolute result at
index `i` is at most `i+1`, so the largest possible result is 64.

## Source and rights

The behavior reference is `s321` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3811)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/Recurrences-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Recurrences-dbl/tsc.c),
which selects `TYPE double` and the recurrence codelets. The source initializes
A to one and B to zero; this bounded profile accepts caller-supplied values so
the recurrence is observable. The TSVC source comments attribute its
non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded loop
contract and reuse no upstream source code or comments; no upstream license or
endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and fixed cases are
[`tsvc_s321_first_order_recurrence_oracle.py`](../../tsvc_s321_first_order_recurrence_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s321_first_order_recurrence.c`](../../../c/t/tsvc_s321_first_order_recurrence.c) |
| C3 | [`tsvc_s321_first_order_recurrence.c3`](../../../c3/t/tsvc_s321_first_order_recurrence.c3) |
| C++ | [`tsvc_s321_first_order_recurrence.cpp`](../../../cpp/t/tsvc_s321_first_order_recurrence.cpp) |
| Elisa | [`tsvc_s321_first_order_recurrence.elisa`](../../../elisa/t/tsvc_s321_first_order_recurrence.elisa) |
| Nim | [`tsvc_s321_first_order_recurrence.nim`](../../../nim/t/tsvc_s321_first_order_recurrence.nim) |
| Odin | [`tsvc_s321_first_order_recurrence.odin`](../../../odin/t/tsvc_s321_first_order_recurrence.odin) |
| Rust | [`tsvc_s321_first_order_recurrence.rs`](../../../rust/t/tsvc_s321_first_order_recurrence.rs) |
| V | [`tsvc_s321_first_order_recurrence.v`](../../../v/t/tsvc_s321_first_order_recurrence.v) |
| Zig | [`tsvc_s321_first_order_recurrence.zig`](../../../zig/t/tsvc_s321_first_order_recurrence.zig) |
