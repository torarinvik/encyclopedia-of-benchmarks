# Matrix product over GF(2)

Multiply an `N × M` binary matrix by an `M × K` binary matrix over `GF(2)`.
The local ports pack each row of the right matrix into a 64-bit word and XOR
the rows selected by each left-matrix row.

## Contract

Input is `[N, M, K, A row-major..., B row-major...]` with every dimension from
1 through 64 and entries equal to 0 or 1. Output is the row-major `N × K`
product, with each bit serialized as one signed 64-bit little-endian integer.
Malformed input returns `-1`; null or undersized output returns `-2` without
writing. The maximum input is 8195 i64 values and the output is at most 32768
bytes.

For each row of `B`, the ports build a packed word. Each output row is the XOR
of the packed `B` rows selected by the corresponding row of `A`. The bounded
complexity is `O(MK + NM ceil(K/64) + NK)` time and `O(M + NK)` words. This
profile caps the dimensions at 64 while the official task allows dimensions up
to 4096.

## Distinctness and provenance

The local classical and Strassen matrix multiplication packages use ordinary
integer arithmetic, and min-plus multiplication uses a different semiring.
This package performs a bit-packed product in the two-element field, where
addition is XOR; it is a distinct arithmetic kernel and representation.

Official contract: [Library Checker — Matrix Product (Mod 2)](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/matrix_product_mod_2/task.md)
and its [limits](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/matrix_product_mod_2/info.toml).
The implementations are clean-room ports of the high-level operation.

[`workload.json`](workload.json) includes square and rectangular inputs,
parity cancellation, malformed entries, and output-buffer errors. The oracle
uses scalar triple-loop multiplication over GF(2), independently of the
packed-row implementation.

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/matrix_product_mod_2.c`](../../../c/m/matrix_product_mod_2.c) |
| C3 | [`c3/m/matrix_product_mod_2.c3`](../../../c3/m/matrix_product_mod_2.c3) |
| C++ | [`cpp/m/matrix_product_mod_2.cpp`](../../../cpp/m/matrix_product_mod_2.cpp) |
| Elisa | [`elisa/m/matrix_product_mod_2.elisa`](../../../elisa/m/matrix_product_mod_2.elisa) |
| Nim | [`nim/m/matrix_product_mod_2.nim`](../../../nim/m/matrix_product_mod_2.nim) |
| Odin | [`odin/m/matrix_product_mod_2.odin`](../../../odin/m/matrix_product_mod_2.odin) |
| Rust | [`rust/m/matrix_product_mod_2.rs`](../../../rust/m/matrix_product_mod_2.rs) |
| V | [`v/m/matrix_product_mod_2.v`](../../../v/m/matrix_product_mod_2.v) |
| Zig | [`zig/m/matrix_product_mod_2.zig`](../../../zig/m/matrix_product_mod_2.zig) |
| Mojo | [`mojo/m/matrix_product_mod_2.mojo`](../../../mojo/m/matrix_product_mod_2.mojo) |
