# TSVC vif positive-mask assignment

This package is a bounded clean-room implementation of TSVC `vif` from the
`ControlLoops-dbl` family. In one ascending sweep, each positive element of B
replaces the corresponding element of A:

```text
if b[i] > 0:
    a[i] = b[i]
```

When `b[i] <= 0`, the original `a[i]` value is retained. Since B is unchanged,
repeating the source loop produces the same A vector after its first sweep;
the package therefore profiles one source-shaped sweep. Its output is the
full resulting A array, so retained and replaced positions remain observable.

This differs from TSVC `vbor`, which benchmarks nested arithmetic throughput,
and from `s343`, which packs positive-mask entries into a shorter output. It
also differs from `s161` and `s273`, whose conditions select among dependent
updates rather than perform this independent elementwise replacement.

## Contract

The exported symbol is `tsvc_vif_masked_assignment`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, a[n], b[n]]`, with `n` in `1..64`.
- Every value is in `[-2,2]`; input is unchanged.
- Visit each index once in ascending order. Copy `b[i]` to `a[i]` only when
  `b[i] > 0`; zero and negative values leave A unchanged.
- On success, output final A as little-endian signed i64 values and return
  `n`. Required output capacity is `8*n` bytes.
- Malformed input returns `-1`. Null output or insufficient capacity returns
  `-2`; input validation takes precedence and errors write no output.

## Source and rights

The behavior reference is `vif` in the pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc)
(the codelet starts at [line 4983](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4983))
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/ControlLoops-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-dbl/tsc.c),
which selects `TYPE double` and control-loop codelets. The source initializes
A to zero and B to positive reciprocal-square values; this bounded profile
accepts caller arrays to exercise both the replacement and retain paths. The
TSVC source attributes its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No
explicit license grant was found in the pinned source or repository material
reviewed. These ports independently implement the bounded mathematical
behavior, reuse no upstream source or comments, and claim no upstream license
or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_vif_masked_assignment_oracle.py`](../../tsvc_vif_masked_assignment_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_vif_masked_assignment.c`](../../../c/t/tsvc_vif_masked_assignment.c) |
| C3 | [`tsvc_vif_masked_assignment.c3`](../../../c3/t/tsvc_vif_masked_assignment.c3) |
| C++ | [`tsvc_vif_masked_assignment.cpp`](../../../cpp/t/tsvc_vif_masked_assignment.cpp) |
| Elisa | [`tsvc_vif_masked_assignment.elisa`](../../../elisa/t/tsvc_vif_masked_assignment.elisa) |
| Nim | [`tsvc_vif_masked_assignment.nim`](../../../nim/t/tsvc_vif_masked_assignment.nim) |
| Odin | [`tsvc_vif_masked_assignment.odin`](../../../odin/t/tsvc_vif_masked_assignment.odin) |
| Rust | [`tsvc_vif_masked_assignment.rs`](../../../rust/t/tsvc_vif_masked_assignment.rs) |
| V | [`tsvc_vif_masked_assignment.v`](../../../v/t/tsvc_vif_masked_assignment.v) |
| Zig | [`tsvc_vif_masked_assignment.zig`](../../../zig/t/tsvc_vif_masked_assignment.zig) |
