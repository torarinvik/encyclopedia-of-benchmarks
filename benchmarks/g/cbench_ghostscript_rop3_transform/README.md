# cBench Ghostscript ROP3 truth-table transformations

This package transforms an 8-bit ROP3 truth-table code. Input is `[mode, code]`, where `code` is 0..255 and mode selects one of the pinned `gsropt.h` macros. The output is the transformed 8-bit code; malformed framing or values return -1. Truth-table index bits are D at bit 0, S at bit 1, and T at bit 2.

| Mode | Source macro | Operation |
| ---: | --- | --- |
| 0 | `rop3_invert_D` | Invert destination input |
| 1 | `rop3_invert_S` | Invert source input |
| 2 | `rop3_invert_T` | Invert texture input |
| 3 | `rop3_know_D_0` | Pin destination to 0 |
| 4 | `rop3_know_D_1` | Pin destination to 1 |
| 5 | `rop3_know_S_0` | Pin source to 0 |
| 6 | `rop3_know_S_1` | Pin source to 1 |
| 7 | `rop3_know_T_0` | Pin texture to 0 |
| 8 | `rop3_know_T_1` | Pin texture to 1 |
| 9 | `rop3_swap_S_T` | Swap source and texture |
| 10 | `rop3_use_D_when_S_0` | Force output to D where S=0 |
| 11 | `rop3_use_D_when_S_1` | Force output to D where S=1 |
| 12 | `rop3_use_D_when_T_0` | Force output to D where T=0 |
| 13 | `rop3_use_D_when_T_1` | Force output to D where T=1 |
| 14 | `rop3_not` | Invert the result |

The ports implement each mode as a mapping over the eight truth-table entries. This transforms the Boolean operation itself; it is distinct from [`cbench_ghostscript_rop3`](../cbench_ghostscript_rop3/README.md), which evaluates one pixel, and [`cbench_ghostscript_rop3_idempotence`](../cbench_ghostscript_rop3_idempotence/README.md) / [`cbench_ghostscript_rop3_operand_usage`](../cbench_ghostscript_rop3_operand_usage/README.md), which query truth-table properties.

Source: [`gsropt.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ghostscript/src/gsropt.h), at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Copyright (C) 1995, 1996 Aladdin Enterprises. The complete Aladdin Free Public License v5 is bundled in [`LICENSE.txt`](LICENSE.txt). It permits modification and redistribution subject to conditions, including restrictive noncommercial distribution terms; those restrictions apply to this source-derived profile and must be observed. The ports are independently written.

The independent truth-table remapping oracle is [`benchmarks/ghostscript_rop3_transform_oracle.py`](../../ghostscript_rop3_transform_oracle.py); workload fixtures include every mode and invalid mode/code cases. No runtime verification is claimed.
