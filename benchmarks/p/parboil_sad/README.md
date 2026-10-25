# Parboil SAD hierarchical motion-search kernel

`parboil_sad` is a bounded clean-room profile of Parboil's CPU SAD path. It
compares one current 16×16 macroblock against a reference image at every
integer displacement in the source's `[-16,16] × [-16,16]` search window. It
computes the 16 leaf 4×4 sum-of-absolute-differences values for each candidate,
then builds the source's six larger block types by hierarchical addition.
This is a video motion-search kernel, distinct from generic image comparison,
pixel filters, and the local mean-absolute-error metric.

## Contract

- The exported scalar symbol is `parboil_sad`; ABI: `i64_array_scalar`.
- Input is 128 signed-i64 values: 64 packed row groups for the current frame,
  followed by 64 for the reference frame. Each image is exactly 16×16 pixels.
- Each group is a nonnegative 32-bit word. A row has four consecutive groups;
  each group packs four grayscale pixels in little-endian byte order, with the
  leftmost pixel in the least-significant byte. Thus each image is represented
  by 16 rows × 4 groups and can express every 8-bit grayscale frame exactly.
- Search displacement order is `dy=-16..16` outside `dx=-16..16`; within each
  candidate, the source visits block row, block column, pixel row, and pixel
  column. Reference coordinates are clamped individually to the nearest image
  edge, as in `sad4_one_macroblock`.
- Each 4×4 SAD is accumulated as an unsigned 16-bit source value. The source
  `larger_sads` hierarchy then constructs block types 6, 5, 4, 3, 2, and 1
  from the corresponding smaller blocks in its original grouping order.
  Unused three padding positions per vector are omitted from computation and
  observation.
- The profile returns the signed-i64 sum of all computed SAD entries: all
  1, 2, 2, 4, 8, 8, and 16 blocks for types 1 through 7, across all 1089 search
  positions. This observable projection makes both the leaf SAD and larger
  block aggregation part of the timed operation. The maximum is
  `255 × 256 × 7 × 1089 = 497,629,440`, which fits signed i64 and every
  individual source u16 SAD.
- Invalid pointers, lengths other than 128, or packed words outside
  `[0, 4,294,967,295]` return `-1`.

The source launcher accepts full images whose dimensions are multiples of 16;
this profile uses its minimum one-macroblock case. Image loading, file output,
GPU texture handling, multi-macroblock scheduling, and timing wrappers are
outside the contract. The independent oracle computes block rectangles by
direct pixel enumeration rather than using the ports' hierarchical sums.

## Source and rights

Pinned source: [`yuhc/gpu-parboil` commit
`ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b).
The principal routines are [`sad_cpu.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/sad/src/base/sad_cpu.c)
(`sad4_cpu`, `sad4_one_macroblock`, and `larger_sads`), with block sizes,
search range, and padded-position constants from
[`sad.h`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/sad/src/base/sad.h).
The source launcher invokes `sad4_cpu` followed by `larger_sads` in
[`main.c`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/sad/src/base/main.c).

The pinned repository distributes Parboil under the Illinois Open Source
License, University of Illinois/NCSA. Its full license text is reproduced in
[`LICENSE.txt`](LICENSE.txt). These ports are independent clean-room
implementations of the documented bounded behavior.

The ports retain the source's candidate-major leaf traversal and `larger_sads`
aggregation order. The independent oracle instead sums every block rectangle
directly from pixels, without deriving larger blocks from the 4×4 results.

Independent oracle: [`benchmarks/parboil_sad_oracle.py`](../../parboil_sad_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`parboil_sad.c`](../../../c/p/parboil_sad.c) |
| C3 | [`parboil_sad.c3`](../../../c3/p/parboil_sad.c3) |
| C++ | [`parboil_sad.cpp`](../../../cpp/p/parboil_sad.cpp) |
| Elisa | [`parboil_sad.elisa`](../../../elisa/p/parboil_sad.elisa) |
| Nim | [`parboil_sad.nim`](../../../nim/p/parboil_sad.nim) |
| Odin | [`parboil_sad.odin`](../../../odin/p/parboil_sad.odin) |
| Rust | [`parboil_sad.rs`](../../../rust/p/parboil_sad.rs) |
| V | [`parboil_sad.v`](../../../v/p/parboil_sad.v) |
| Zig | [`parboil_sad.zig`](../../../zig/p/parboil_sad.zig) |
