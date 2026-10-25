# Rodinia forward integer 5/3 2D DWT

`rodinia_dwt2d` is an independent scalar implementation of the forward integer LeGall 5/3 wavelet transform in Rodinia's CUDA `dwt2d` benchmark. The selected launcher path is `run.sh`'s `-f -5` mode: forward, integer 5/3. This is not the default floating-point 9/7 path. The source also supports one grayscale component; this profile follows that path and makes the pixel plane explicit instead of including BMP parsing, RGB splitting, CUDA allocation, device launches, or timing wrappers.

## Contract

The export uses the `i64_array_bytes_output` ABI and the symbol `rodinia_dwt2d`. Input is `[width, height, levels, row_major_grayscale_bytes...]`. Width and height are each 2 through 16, levels are 1 through 3, and both dimensions must be divisible by `2^levels` and at least that large. The image contains exactly `width*height` values, each in `0..255`. These bytes are normalized with the source's integer grayscale conversion `pixel - 128`.

Each level follows the source's operation order: lift columns first, then rows, and recurse only into the top-left low-low region. For each 1D line, predict an odd sample by subtracting the truncation-toward-zero average of its neighboring even samples; update every even sample with the truncation-toward-zero expression `(previous_detail + next_detail + 2) / 4`. At the left boundary, the source uses the first detail twice; at the right edge, its single reflection maps the missing even neighbor to the preceding even sample. Coefficients are packed low-before-high on each axis, in row-major band order: low-low, vertical-low/horizontal-high, vertical-high/horizontal-low, high-high. Deeper-level bands replace the prior low-low area, matching the source's contiguous coefficient layout.

The output contains all `width*height` coefficients, each encoded as signed 32-bit little-endian bytes; success returns `4*width*height`. Coefficients are stored in consecutive row-major band chunks: the deepest level's LL, HL, LH, and HH bands first, followed by the three detail bands at each less-deep level. This is Rodinia's linear band layout rather than an ordinary row-major image of quadrants. Invalid input returns `-1`; null or short output returns `-2` without writes. Input length must equal `3 + width*height`.

The smaller square/evenly divisible domain is a deterministic bounded profile of the source method. It excludes odd-size rounding behavior, 9/7 floating-point lifting, inverse transforms, visual/tiled output, BMP and RGB file handling, CUDA scheduling, and timing. These ports preserve the source recurrence and coefficient organization without copying or translating upstream implementation text.

## Pinned source and rights

- Repository: [`utcs-scea/rodinia`](https://github.com/utcs-scea/rodinia)
- Commit: `f30e63663cfb114939a15c7ffc4ae112055ae6a8`
- Launcher: [`cuda/dwt2d/run.sh`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/dwt2d/run.sh), which selects forward 5/3 with `-f -5`.
- Core recurrence: [`fdwt53.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/dwt2d/dwt_cuda/fdwt53.cu) and [`transform_buffer.h`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/dwt2d/dwt_cuda/transform_buffer.h).
- Input normalization and host dispatch: [`components.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/dwt2d/components.cu), [`main.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/dwt2d/main.cu), and [`dwt.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/dwt2d/dwt.cu).
- The complete Jiri Matela (2009) and Martin Jirman (2011) two-condition notices, plus the University of Virginia BSD-3-Clause notice and Rodinia citation request, are included in [`LICENSE.txt`](LICENSE.txt).

[`workload.json`](workload.json) records the input/output limits and hand-derived fixtures. [`rodinia_dwt2d_oracle.py`](../../rodinia_dwt2d_oracle.py) is a separate split-even/odd reference model.

| Language | Port |
|---|---|
| C | [`c/r/rodinia_dwt2d.c`](../../../c/r/rodinia_dwt2d.c) |
| C3 | [`c3/r/rodinia_dwt2d.c3`](../../../c3/r/rodinia_dwt2d.c3) |
| C++ | [`cpp/r/rodinia_dwt2d.cpp`](../../../cpp/r/rodinia_dwt2d.cpp) |
| Elisa | [`elisa/r/rodinia_dwt2d.elisa`](../../../elisa/r/rodinia_dwt2d.elisa) |
| Nim | [`nim/r/rodinia_dwt2d.nim`](../../../nim/r/rodinia_dwt2d.nim) |
| Odin | [`odin/r/rodinia_dwt2d.odin`](../../../odin/r/rodinia_dwt2d.odin) |
| Rust | [`rust/r/rodinia_dwt2d.rs`](../../../rust/r/rodinia_dwt2d.rs) |
| V | [`v/r/rodinia_dwt2d.v`](../../../v/r/rodinia_dwt2d.v) |
| Zig | [`zig/r/rodinia_dwt2d.zig`](../../../zig/r/rodinia_dwt2d.zig) |

No code, compilers, tests, or validators were run for this package.
