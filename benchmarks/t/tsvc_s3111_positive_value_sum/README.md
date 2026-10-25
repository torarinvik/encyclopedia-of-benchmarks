# TSVC s3111 positive-value sum

This package is a bounded clean-room profile of TSVC `s3111` from the
`Reductions-dbl` launcher family. It returns the sum of entries that are
strictly positive:

```text
sum = Σ a[i] where a[i] > 0
```

This differs from the repository's `array_sum`, which includes negative
entries, and from `s311`'s unconditional sum reduction. The pinned TSVC
initialization sets `a[i] = 1/(i+1)`, so every default element is positive and
the conditional branch does not filter values in that source workload. This
profile accepts bounded mixed-sign integer data to make the source's strict
positive predicate observable while retaining the same reduction operation.

## Contract

The exported symbol is `tsvc_s3111_positive_value_sum`, using the
`i64_array_scalar` ABI:

- Input is `[n, values[n]]`, with `n` in `0..64`.
- Each value is in `[-1,000,000, 1,000,000]`.
- Sum values strictly greater than zero; zero and negative values contribute
  nothing. An empty input array returns zero.
- Malformed shape, count, or values return `-1`.

The largest result is at most 64,000,000, which is exact in the source
binary64 profile and fits signed i64.

## Source and rights

The kernel is pinned `s3111` at lines 3717–3744 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3717)
in LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/Reductions-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-dbl/tsc.c),
which selects `TYPE double` and the reductions family. Source initialization
for `s3111` is at `TSVC/tsc.inc` lines 586–587. The TSVC source comments
attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded loop
contract and reuse no upstream source code or comments; no upstream license or
endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle and fixed workload are
[`tsvc_s3111_positive_value_sum_oracle.py`](../../tsvc_s3111_positive_value_sum_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s3111_positive_value_sum.c`](../../../c/t/tsvc_s3111_positive_value_sum.c) |
| C3 | [`tsvc_s3111_positive_value_sum.c3`](../../../c3/t/tsvc_s3111_positive_value_sum.c3) |
| C++ | [`tsvc_s3111_positive_value_sum.cpp`](../../../cpp/t/tsvc_s3111_positive_value_sum.cpp) |
| Elisa | [`tsvc_s3111_positive_value_sum.elisa`](../../../elisa/t/tsvc_s3111_positive_value_sum.elisa) |
| Nim | [`tsvc_s3111_positive_value_sum.nim`](../../../nim/t/tsvc_s3111_positive_value_sum.nim) |
| Odin | [`tsvc_s3111_positive_value_sum.odin`](../../../odin/t/tsvc_s3111_positive_value_sum.odin) |
| Rust | [`tsvc_s3111_positive_value_sum.rs`](../../../rust/t/tsvc_s3111_positive_value_sum.rs) |
| V | [`tsvc_s3111_positive_value_sum.v`](../../../v/t/tsvc_s3111_positive_value_sum.v) |
| Zig | [`tsvc_s3111_positive_value_sum.zig`](../../../zig/t/tsvc_s3111_positive_value_sum.zig) |
