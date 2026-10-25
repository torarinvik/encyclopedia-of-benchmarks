# TSVC s281 reverse-coupled update

This package isolates TSVC's `s281` in-place array update. Each pass traverses
indices in ascending order while reading `a` in reverse index order, then
updates `a[i]` and `b[i]`. The order matters: in the second half of a pass, a
reverse-index read can observe an `a` value written earlier in that same pass.

## Contract

The ABI is `tsvc_s281_reverse_coupled_update` with `i64_array_bytes_output`
framing:

- Input: `[n, passes, A[0..n), B[0..n), C[0..n)]`.
- `n` is 1–16; `passes` is 1–8. The exact input length is `2 + 3*n`.
- `A` and `B` entries are integers in `[-2, 2]`; `C` entries are integers in
  `[-1, 1]`. They represent integer-valued source `double` elements.
- For each pass and each ascending `i`, evaluate `x = A[n-i-1] + B[i]*C[i]`,
  then store `A[i] = x - 1` followed by `B[i] = x`. `C` is unchanged.
- Output contains final `A` then final `B`, each as little-endian signed i64
  values. The function returns the output byte count (`16*n`).
- Malformed or null input returns `-1`; null output or insufficient capacity
  returns `-2` without writing. Maximum input length is 50 and maximum output
  workspace is 256 bytes.

The bounded integer-valued domain keeps all intermediate binary64 values exact:
with the given sizes, pass count, and element ranges, magnitudes remain below
20,000. This makes the byte output portable while preserving the source's
`double` arithmetic and its ascending traversal/in-place dependencies.

## Source and rights

The behavior reference is `s281` in
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc),
included by `TSVC/CrossingThresholds-dbl/tsc.c` at LAC-DCC Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The pinned launcher is
[`TSVC/CrossingThresholds-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/CrossingThresholds-dbl/info.sh); it compiles `dummy.c` and `tsc.c` with `-std=gnu99 -lm` and invokes the benchmark with `5880 14`. The launcher runs the TSVC timing/checksum harness; this profile instead bounds a single source-shaped codelet over explicit arrays and pass counts.

The source attributes its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine's *Test Suite for Vectorizing Compilers*. No explicit
license grant was found in the pinned TSVC source or repository material
reviewed here. The ports are clean-room implementations of the loop behavior;
no upstream code or comments were reused. This package does not claim an
upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the
rights note.

## Workload and oracle

[`workload.json`](workload.json) includes the source initializer pattern, a
fixture that distinguishes same-pass reverse reads from snapshot reads,
multiple passes, negative/zero coefficients, a one-element case, malformed
length/range cases, and output errors. The independent oracle is
[`tsvc_s281_reverse_coupled_update_oracle.py`](../../tsvc_s281_reverse_coupled_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s281_reverse_coupled_update.c`](../../../c/t/tsvc_s281_reverse_coupled_update.c) |
| C3 | [`tsvc_s281_reverse_coupled_update.c3`](../../../c3/t/tsvc_s281_reverse_coupled_update.c3) |
| C++ | [`tsvc_s281_reverse_coupled_update.cpp`](../../../cpp/t/tsvc_s281_reverse_coupled_update.cpp) |
| Elisa | [`tsvc_s281_reverse_coupled_update.elisa`](../../../elisa/t/tsvc_s281_reverse_coupled_update.elisa) |
| Nim | [`tsvc_s281_reverse_coupled_update.nim`](../../../nim/t/tsvc_s281_reverse_coupled_update.nim) |
| Odin | [`tsvc_s281_reverse_coupled_update.odin`](../../../odin/t/tsvc_s281_reverse_coupled_update.odin) |
| Rust | [`tsvc_s281_reverse_coupled_update.rs`](../../../rust/t/tsvc_s281_reverse_coupled_update.rs) |
| V | [`tsvc_s281_reverse_coupled_update.v`](../../../v/t/tsvc_s281_reverse_coupled_update.v) |
| Zig | [`tsvc_s281_reverse_coupled_update.zig`](../../../zig/t/tsvc_s281_reverse_coupled_update.zig) |
