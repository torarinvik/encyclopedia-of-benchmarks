# cBench Ghostscript ROP3 idempotence predicate

This package evaluates the source-defined `rop3_is_idempotent(op)` predicate on one 8-bit ROP3 code. Input is a one-element signed-i64 array `[code]`, with `code` in 0..255; the result is 1 or 0, and invalid framing/value returns -1. This measures a property of the truth table. It does not return the pixel result computed by [`cbench_ghostscript_rop3`](../cbench_ghostscript_rop3/README.md).

The pinned `gsropt.h` comment describes mathematical idempotence as rejecting any `(S,T)` for which `f(0,S,T)=1` and `f(1,S,T)=0`. The header macro itself is the compatibility contract: `!(op & ~(op << rop3_D_shift) & rop3_D)`. The ports preserve that expression's 8-bit ROP-code behavior exactly, including the source macro's result for code `0xaa`. This avoids silently replacing the source implementation with the prose condition.

Source: [`gsropt.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ghostscript/src/gsropt.h), at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Copyright (C) 1995, 1996 Aladdin Enterprises. The complete Aladdin Free Public License v5 is bundled in [`LICENSE.txt`](LICENSE.txt); it allows modification and redistribution subject to its conditions, including restrictive noncommercial distribution terms. Observe those terms for this source-derived profile. The ports are independently written.

The independent oracle is [`benchmarks/ghostscript_rop3_idempotence_oracle.py`](../../ghostscript_rop3_idempotence_oracle.py). Workload fixtures are in [`workload.json`](workload.json). No runtime verification is claimed.
