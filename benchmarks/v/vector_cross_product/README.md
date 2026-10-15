# Vector cross product

## Contract

The pinned C++ and Rust sources compute the cross product of two three-dimensional vectors and provide a helper for vector magnitude. The benchmark accepts six signed integers in `[A.x, A.y, A.z, B.x, B.y, B.z]`, each in `[-1,000,000, 1,000,000]`. This bounded integer domain is represented exactly by the sources’ binary64 vector type, and every cross component is an exact integer.

The output is 32 bytes: four signed 64-bit integers in little-endian order, `[cross.x, cross.y, cross.z, magnitude_micro]`. The cross components follow `A × B` order: `[Ay*Bz-Az*By, -(Ax*Bz-Az*Bx), Ax*By-Ay*Bx]`. `magnitude_micro` is the Euclidean magnitude of that cross vector rounded to the nearest millionth using `floor(magnitude * 1,000,000 + 0.5)`. The bound keeps this scaled magnitude within signed 64-bit range. Inputs with a wrong length or a component outside the bound return `-1`.

The workload uses the existing `i64_array_bytes_output` ABI. Its input limit permits all six values, and its 400,004-byte output limit exceeds the fixed 32-byte result.

## Workload and implementation

[`workload.json`](workload.json) contains orthogonal, parallel, negative, source-example, and bounded large-vector cases, plus invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/v/vector_cross_product.c`](../../../c/v/vector_cross_product.c) |
| C3 | [`c3/v/vector_cross_product.c3`](../../../c3/v/vector_cross_product.c3) |
| C++ | [`cpp/v/vector_cross_product.cpp`](../../../cpp/v/vector_cross_product.cpp) |
| Elisa | [`elisa/v/vector_cross_product.elisa`](../../../elisa/v/vector_cross_product.elisa) |
| Nim | [`nim/v/vector_cross_product.nim`](../../../nim/v/vector_cross_product.nim) |
| Odin | [`odin/v/vector_cross_product.odin`](../../../odin/v/vector_cross_product.odin) |
| Rust | [`rust/v/vector_cross_product.rs`](../../../rust/v/vector_cross_product.rs) |
| V | [`v/v/vector_cross_product.v`](../../../v/v/vector_cross_product.v) |
| Zig | [`zig/v/vector_cross_product.zig`](../../../zig/v/vector_cross_product.zig) |

## Pinned sources

- [C++ `vector_cross_product.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/vector_cross_product.cpp)
- [C++-1 `vector_cross_product.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/vector_cross_product.cpp)
- [Rust `vector_cross_product.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/vector_cross_product.rs)
