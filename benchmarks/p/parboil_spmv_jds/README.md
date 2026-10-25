# Parboil JDS sparse matrix–vector product

This package isolates the preconverted Jagged Diagonal Storage (JDS) SpMV kernel from Parboil's `spmv` benchmark. Provenance is pinned to `yuhc/gpu-parboil` commit `ccf3d3126f1754ca85528722f4ced5894ccb852b`, especially `benchmarks/spmv/src/cpu/main.c` (`coo_to_jds`, `input_vec`, `main`). The complete applicable Illinois Open Source License is in [LICENSE.txt](LICENSE.txt).

The input contains dimension, JDS depth, nonzero count, row lengths, row permutation, diagonal prefix offsets, column indexes, matrix values, and vector values. It represents already converted JDS data; COO parsing and symmetric expansion are outside this profile. Row lengths must be nonincreasing, the permutation bijective, and each diagonal's length/prefix must match those row lengths. Dimensions and depths are at most eight.

Values use signed Q1e-6 integers and are converted to binary32. Each row rank is evaluated in order, with `j = ptr[k] + rank`; each matrix/vector product is rounded to binary32, then added to a binary32 accumulator in increasing diagonal order. The result is stored at `perm[rank]`. This preserves the source loop's JDS traversal and single-precision accumulation order. The output is little-endian `uint32 dimension` followed by row-major IEEE binary32 values.

The profile excludes the source benchmark's file/CLI handling, COO-to-JDS conversion, repeated timing loop, and device/runtime behavior. The ports are clean-room implementations of the bounded kernel contract. The source license is reproduced verbatim; no runtime verification is claimed here.
