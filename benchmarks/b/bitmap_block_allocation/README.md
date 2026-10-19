# Bitmap block-allocation simulation

Exercise bitmap block allocation operations with the NBench Bitfield kernel's set-run, clear-run, and complement-run sequence. The bounded workload supplies each run explicitly, avoiding random-number-generator and timing-loop dependencies while retaining the bit-level work.

## Contract

Input is a signed-i64 array `[bit_count, operation_count, offset_0, length_0, ...]`. `bit_count` is 1–4096; there are 0–32 operations. The exact input length is `2 + 2*operation_count`; each range satisfies `0 <= offset <= bit_count` and `0 <= length <= bit_count-offset`. The bitmap starts in the source's alternating `0x55...` pattern: even-numbered bits are set. Operations are applied in order: operation indices congruent to 0 modulo 3 set the run, 1 clear it, and 2 complement it. Output packs the final bitmap into `ceil(bit_count/8)` bytes, with bit 0 in the low bit of byte 0 and unused high bits zero. Success returns the output byte count. Invalid input returns `-1`; null or short output returns `-2` without writes. Maximum output is 512 bytes.

## Upstream attribution and terms

This is a new bounded implementation based on the operation sequence in ANSIbench's NBench BYTEmark source, `nbench/src/nbench1.c` (`DoBitfieldIteration`, `ToggleBitRun`, `FlipBitRun`), pinned at [nfinit/ansibench commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c). NBench credits Rick Grehan/BYTE Magazine for BYTEmark and Uwe F. Mayer for the Linux/Unix port. No source blocks are copied.

The upstream BYTEmark notice makes the source, executable, and documentation available “as is” and disclaims warranties and liability. Preserve that notice and upstream attribution when redistributing derived work; the upstream package is commonly tagged `freedist`, not a standard permissive license. The notice is included as [NBENCH-LICENSE](NBENCH-LICENSE) and is also available at [`nbench/LICENSE`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/LICENSE).

## ABI

Uses `i64_array_bytes_output`: exported `bitmap_block_allocation(values, length, output, output_capacity)` returns the number of output bytes, `-1` for invalid input, and `-2` for null/short output.
