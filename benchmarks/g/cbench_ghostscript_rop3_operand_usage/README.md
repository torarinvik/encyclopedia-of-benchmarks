# cBench Ghostscript ROP3 operand usage

This bounded helper reports which of the destination, source, and texture inputs affect an 8-bit RasterOp truth table. Input is `[code]` for `code` in 0..255. The output is a mask with destination bit 1, source bit 2, and texture bit 4; constant functions return zero. Invalid framing or values return -1.

The pinned `gsropt.h` defines `rop3_uses_D`, `rop3_uses_S`, and `rop3_uses_T` by comparing each truth-table entry with the entry obtained by toggling that operand. The ports implement that dependency test by pairwise truth-table comparison. This operation is distinct from [`cbench_ghostscript_rop3`](../cbench_ghostscript_rop3/README.md), which computes a pixel result, and [`cbench_ghostscript_rop3_idempotence`](../cbench_ghostscript_rop3_idempotence/README.md), which tests a different property of the truth table.

Source: [`gsropt.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ghostscript/src/gsropt.h), at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Copyright (C) 1995, 1996 Aladdin Enterprises. The full Aladdin Free Public License v5 is bundled in [`LICENSE.txt`](LICENSE.txt); it permits modification and redistribution subject to conditions, including restrictive noncommercial distribution terms. Those restrictions apply to this source-derived profile and must be observed. The ports are independent implementations.

The independent truth-table oracle is [`benchmarks/ghostscript_rop3_operand_usage_oracle.py`](../../ghostscript_rop3_operand_usage_oracle.py); fixtures are in [`workload.json`](workload.json). No runtime verification is claimed.
