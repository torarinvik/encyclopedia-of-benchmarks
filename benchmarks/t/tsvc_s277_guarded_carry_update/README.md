# TSVC s277 guarded carry update

This package is a bounded clean-room profile of TSVC `s277` from the
`ControlFlow-dbl` family. Its ordered guards decide whether to update the
current A element and then write the next B element:

```text
for i = 0 .. n-2 in ascending order:
    if A[i] >= 0: skip this index
    if B[i] < 0: A[i] += C[i] * D[i]
    B[i+1] = C[i] + D[i] * E[i]
```

The `B[i+1]` write occurs whenever `A[i] < 0`, even if `B[i] >= 0`; the B test
guards only the A update. The loop is ascending, so a B value written by one
iteration can select the next iteration's path. The last A and B elements are
never used as loop indices, though `B[n-1]` may be written by the preceding
iteration.

## Contract

The exported symbol is `tsvc_s277_guarded_carry_update`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, A[n], B[n], C[n], D[n], E[n]]`, with `n` in 1 through
  64 and `passes` in 1 through 8.
- All input array values are in `[-2,2]`.
- For each pass, visit `i=0..n-2` in ascending order, preserving both guards
  and the update order shown above.
- On success, output final A followed by final B as little-endian signed i64
  values and return `2*n`.
- Malformed input returns `-1`; null output or capacity below `16*n` bytes
  returns `-2` without writing output.

The bounded range keeps A in `[-34,34]` and B in `[-6,6]`; all products and
additions are exact in the source's binary64 `TYPE` and fit signed i64. The
source initializer has half-positive/half-negative A and B vectors, with
fractional C/D/E values. This profile uses bounded integers to make both guard
paths and the carried B dependency directly reproducible. Timing and checker
code are outside the package.

This is distinct from s273's same-index dependent A update and conditionally
updated B, s274's computed-value branch, and s278's branch-controlled B/C write
followed by a common A recomputation. Here a negative A guards a next-element B
overwrite, and the updated B participates in the next loop iteration's test.

## Source and rights

The behavior reference is `s277` in `TSVC/tsc.inc`, lines 2858–2890, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2858). The ordered kernel is at lines 2869–2882. The
[`ControlFlow-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c)
selects double precision; its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/info.sh)
uses run options `2325 14`. TSVC comments attribute its non-four-digit
codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for
Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream code or comments. No upstream license or endorsement is
claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s277_guarded_carry_update_oracle.py`](../../tsvc_s277_guarded_carry_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s277_guarded_carry_update.c`](../../../c/t/tsvc_s277_guarded_carry_update.c) |
| C3 | [`tsvc_s277_guarded_carry_update.c3`](../../../c3/t/tsvc_s277_guarded_carry_update.c3) |
| C++ | [`tsvc_s277_guarded_carry_update.cpp`](../../../cpp/t/tsvc_s277_guarded_carry_update.cpp) |
| Elisa | [`tsvc_s277_guarded_carry_update.elisa`](../../../elisa/t/tsvc_s277_guarded_carry_update.elisa) |
| Nim | [`tsvc_s277_guarded_carry_update.nim`](../../../nim/t/tsvc_s277_guarded_carry_update.nim) |
| Odin | [`tsvc_s277_guarded_carry_update.odin`](../../../odin/t/tsvc_s277_guarded_carry_update.odin) |
| Rust | [`tsvc_s277_guarded_carry_update.rs`](../../../rust/t/tsvc_s277_guarded_carry_update.rs) |
| V | [`tsvc_s277_guarded_carry_update.v`](../../../v/t/tsvc_s277_guarded_carry_update.v) |
| Zig | [`tsvc_s277_guarded_carry_update.zig`](../../../zig/t/tsvc_s277_guarded_carry_update.zig) |
