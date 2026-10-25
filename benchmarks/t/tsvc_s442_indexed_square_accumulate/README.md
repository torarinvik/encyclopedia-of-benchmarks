# TSVC s442 indexed square accumulate

This package is a bounded, clean-room profile of TSVC `s442` in the
`ControlFlow-dbl` family. The source uses an integer-indexed computed-goto
dispatch to choose one of four input arrays. For each position, it adds the
square of the selected value to A:

```text
selector[i] == 1: A[i] += B[i] * B[i]
selector[i] == 2: A[i] += C[i] * C[i]
selector[i] == 3: A[i] += D[i] * D[i]
selector[i] == 4: A[i] += E[i] * E[i]
```

The codelet's pinned `set` routine cycles selector tags through 1–4. The
bounded interface accepts any valid tag per index and a bounded pass count.
This operation differs from s278's A-sign-driven branch, which updates either
B or C and recomputes A, and from s273's dependent threshold branch. No local
package for `s442` or an equivalent indexed four-way square-accumulation
kernel was found during the static package and suite search.

## Contract

The exported symbol is `tsvc_s442_indexed_square_accumulate`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, A[n], B[n], C[n], D[n], E[n], selector[n]]`, where
  `n` is in `1..64` and `passes` in `1..16`.
- Each array value is in `[-2,2]`; each selector is in `1..4`.
- For each pass in order and each index in ascending order, select B/C/D/E
  from tags 1/2/3/4 respectively and add its square to A[i].
- Emit final A as little-endian signed i64 values and return `n`. Required
  output capacity is `8*n` bytes. Inputs are unchanged.
- Malformed input returns `-1`; null output or insufficient capacity returns
  `-2` without writes.

The bounded pass count replaces the source timing loop while preserving the
state update at each pass. The source's default index sequence can be
reproduced by using `((i + 1) % 4) + 1`; fixtures also exercise all four arms.

## Source and rights

The behavior reference is `s442` at lines 4412–4451 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4412),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/ControlFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c).
TSVC comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s442_indexed_square_accumulate_oracle.py`](../../tsvc_s442_indexed_square_accumulate_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s442_indexed_square_accumulate.c`](../../../c/t/tsvc_s442_indexed_square_accumulate.c) |
| C3 | [`tsvc_s442_indexed_square_accumulate.c3`](../../../c3/t/tsvc_s442_indexed_square_accumulate.c3) |
| C++ | [`tsvc_s442_indexed_square_accumulate.cpp`](../../../cpp/t/tsvc_s442_indexed_square_accumulate.cpp) |
| Elisa | [`tsvc_s442_indexed_square_accumulate.elisa`](../../../elisa/t/tsvc_s442_indexed_square_accumulate.elisa) |
| Nim | [`tsvc_s442_indexed_square_accumulate.nim`](../../../nim/t/tsvc_s442_indexed_square_accumulate.nim) |
| Odin | [`tsvc_s442_indexed_square_accumulate.odin`](../../../odin/t/tsvc_s442_indexed_square_accumulate.odin) |
| Rust | [`tsvc_s442_indexed_square_accumulate.rs`](../../../rust/t/tsvc_s442_indexed_square_accumulate.rs) |
| V | [`tsvc_s442_indexed_square_accumulate.v`](../../../v/t/tsvc_s442_indexed_square_accumulate.v) |
| Zig | [`tsvc_s442_indexed_square_accumulate.zig`](../../../zig/t/tsvc_s442_indexed_square_accumulate.zig) |
