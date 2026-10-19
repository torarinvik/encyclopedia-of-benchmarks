# VersaBench BMM

This package ports the blocked matrix multiplication in the pinned VersaBench `bmm.c`. The launcher selects `128 32` with `SMALL_PROBLEM_SIZE` and `1024 1024` otherwise. The suite uses the bounded small profile, accepting `[NUM, BLOCK]` with `1 <= NUM <= 128`, `1 <= BLOCK <= NUM`, and `NUM` divisible by `BLOCK`. The largest call performs 2,097,152 multiply-add updates.

The source initializes fixed 1024-by-1024 single-precision matrices from the 32-bit LCG seeded with 1. It consumes two random draws per cell in row-major order, applies the source's `(j-i)&31` and `(i+j)&31` shifts, multiplies blocks in `i`, `j`, `k` tile order, and sums each output block in row-major order before adding block sums. Ports generate the active rows while consuming all 1024 columns of each row, preserving the source values at the bounded dimensions. Source values and products are exact small integers; the ports preserve binary32 accumulation in the block sums and final sum.

The C ABI is:

```c
int64_t versabench_bmm(const int64_t *input, size_t length,
                       uint8_t *output, size_t output_capacity);
```

Input is exactly `[NUM, BLOCK]`. Success returns the byte length of the source-style ASCII report `final sum = %f\n` (six fractional digits). Invalid input returns `-1`. For valid input, a null output or insufficient capacity returns `-2` without writing. The maximum output is 29 bytes. The independent oracle reproduces the LCG and binary32 accumulation separately from the ports.

The pinned source contains Hewlett-Packard's restrictive software license notice. Its complete notice is preserved in [`LICENSE`](LICENSE); these language files are modified bounded-profile ports, not the original program. The license limits use to academic, research, and internal business purposes and requires separate written permission for commercial use.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bmm.c`](../../../c/b/bmm.c) |
| C3 | [`c3/b/bmm.c3`](../../../c3/b/bmm.c3) |
| C++ | [`cpp/b/bmm.cpp`](../../../cpp/b/bmm.cpp) |
| Elisa | [`elisa/b/bmm.elisa`](../../../elisa/b/bmm.elisa) |
| Nim | [`nim/b/bmm.nim`](../../../nim/b/bmm.nim) |
| Odin | [`odin/b/bmm.odin`](../../../odin/b/bmm.odin) |
| Rust | [`rust/b/bmm.rs`](../../../rust/b/bmm.rs) |
| V | [`v/b/bmm.v`](../../../v/b/bmm.v) |
| Zig | [`zig/b/bmm.zig`](../../../zig/b/bmm.zig) |

## Pinned source

- [`bmm.c` at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/bmm/bmm.c)
- [`info.sh` at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/bmm/info.sh)
- [`workload.json`](workload.json)
- [independent oracle](../../versabench_bmm_oracle.py)
