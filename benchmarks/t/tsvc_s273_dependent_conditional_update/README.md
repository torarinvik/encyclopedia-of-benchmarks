# TSVC s273 dependent conditional update

This package isolates the `s273` codelet from the pending TSVC
`ControlFlow-dbl` launcher. For every array position it first updates A, tests
that updated A for negativity, conditionally updates B, and then updates C
using the same updated A. The order gives the branch its data dependency and
is the defining behavior of this source kernel.

## Contract

The ABI is `tsvc_s273_dependent_conditional_update` with
`i64_array_scalar_call` framing:

- Input: `[n, passes, A[0..n), B[0..n), C[0..n), D[0..n), E[0..n)]`.
- `n` is in `1..64`; `passes` is in `1..8`; the exact input length is
  `2 + 5*n`.
- Entries in all five arrays are in `[-2,2]`; malformed input returns `-1`.
- For each pass and each ascending index, perform `A[i] += D[i]*E[i]`; if the
  updated `A[i] < 0`, perform `B[i] += D[i]*E[i]`; then perform
  `C[i] += A[i]*D[i]` using the updated A.
- Return the sum of final A, B, and C. D and E are unchanged, and the caller's
  input buffer is preserved.

The source uses `double`, but these bounds keep every intermediate an exact
integer in binary64 and well within signed i64. The launcher repetition and
timing/dummy-call scaffolding are outside this bounded workload.

## Source and rights

The source is `s273` in
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2842)
at pinned LAC-DCC Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; it is included by
[`TSVC/ControlFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c).
The launcher is
[`TSVC/ControlFlow-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/info.sh);
it compiles `dummy.c` and `tsc.c` with `-lm -std=gnu99` and runs with
`2325 14`. The original `s273` uses `LEN=32000` and `ntimes=2325`; this package
bounds its explicit-array profile to 64 entries and eight passes.

The TSVC source comment attributes the non-four-digit codelets to David
Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*. No explicit license grant was found in the pinned TSVC source or
repository material reviewed. These ports are independent implementations of
the documented loop behavior and reuse no upstream source text or comments. No
upstream license or endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt)
for the rights note.

## Workload and oracle

[`workload.json`](workload.json) covers both outcomes of the dependent branch,
the updated-value branch transition on a later pass, multiple elements, and
invalid inputs. The independent oracle is
[`tsvc_s273_dependent_conditional_update_oracle.py`](../../tsvc_s273_dependent_conditional_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s273_dependent_conditional_update.c`](../../../c/t/tsvc_s273_dependent_conditional_update.c) |
| C3 | [`tsvc_s273_dependent_conditional_update.c3`](../../../c3/t/tsvc_s273_dependent_conditional_update.c3) |
| C++ | [`tsvc_s273_dependent_conditional_update.cpp`](../../../cpp/t/tsvc_s273_dependent_conditional_update.cpp) |
| Elisa | [`tsvc_s273_dependent_conditional_update.elisa`](../../../elisa/t/tsvc_s273_dependent_conditional_update.elisa) |
| Nim | [`tsvc_s273_dependent_conditional_update.nim`](../../../nim/t/tsvc_s273_dependent_conditional_update.nim) |
| Odin | [`tsvc_s273_dependent_conditional_update.odin`](../../../odin/t/tsvc_s273_dependent_conditional_update.odin) |
| Rust | [`tsvc_s273_dependent_conditional_update.rs`](../../../rust/t/tsvc_s273_dependent_conditional_update.rs) |
| V | [`tsvc_s273_dependent_conditional_update.v`](../../../v/t/tsvc_s273_dependent_conditional_update.v) |
| Zig | [`tsvc_s273_dependent_conditional_update.zig`](../../../zig/t/tsvc_s273_dependent_conditional_update.zig) |
