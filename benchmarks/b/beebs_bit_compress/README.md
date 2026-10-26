# BEEBS masked bit compression

This benchmark extracts the data bits selected by a 32-bit mask and packs them into consecutive low-order result bits. It implements the bounded operation exercised by `compress1`, `compress2`, `compress3`, and `compress4` in the pinned BEEBS `aha-compress` source. Those four routines are alternate algorithms for the same bit-compress contract, so this package records one canonical operation rather than four duplicate benchmarks.

The `i64_array_scalar` input is exactly `[data_u32, mask_u32]`. Both values must be in `0..=4,294,967,295`. The operation visits source bit positions from least significant to most significant. Whenever the mask selects a position, the corresponding data bit is copied to the next result position, beginning at bit 0. The result is in `0..=4,294,967,295`; malformed frames and out-of-range values return `-1`.

This arbitrary-mask bit gather is distinct from [`select_bits`](../../s/select_bits/README.md), which extracts one contiguous interval of bit positions.

The workload includes every source test vector from `compress_test.c` plus boundary and invalid cases. [`workload.json`](workload.json) records the pinned source and rights context. [`beebs_bit_compress_oracle.py`](../../beebs_bit_compress_oracle.py) computes the result by enumerating set mask bits and counting earlier selected positions, independently of the port loop.

## Source and rights

Pinned source: [`src/aha-compress/compress_test.c`](https://github.com/mageec/beebs/blob/049ded9f3aeb5591f553879d3a0376b8614e9422/src/aha-compress/compress_test.c), commit `049ded9f3aeb5591f553879d3a0376b8614e9422`. Its `compress1` through `compress4` implementations occupy the bit-compress section; the source test vectors identify the expected packed values. The file declares GPL-3.0-or-later and copyright by Embecosm Limited and the University of Bristol. It attributes the example algorithms to “GLS” without a separate rights statement. The ports here are independently written from the operation and test vectors; no upstream implementation text or comments were copied. The GPL notice and license text are retained in [`LICENSE.txt`](LICENSE.txt).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/beebs_bit_compress.c`](../../../c/b/beebs_bit_compress.c) |
| C3 | [`c3/b/beebs_bit_compress.c3`](../../../c3/b/beebs_bit_compress.c3) |
| C++ | [`cpp/b/beebs_bit_compress.cpp`](../../../cpp/b/beebs_bit_compress.cpp) |
| Elisa | [`elisa/b/beebs_bit_compress.elisa`](../../../elisa/b/beebs_bit_compress.elisa) |
| Nim | [`nim/b/beebs_bit_compress.nim`](../../../nim/b/beebs_bit_compress.nim) |
| Odin | [`odin/b/beebs_bit_compress.odin`](../../../odin/b/beebs_bit_compress.odin) |
| Rust | [`rust/b/beebs_bit_compress.rs`](../../../rust/b/beebs_bit_compress.rs) |
| V | [`v/b/beebs_bit_compress.v`](../../../v/b/beebs_bit_compress.v) |
| Zig | [`zig/b/beebs_bit_compress.zig`](../../../zig/b/beebs_bit_compress.zig) |
