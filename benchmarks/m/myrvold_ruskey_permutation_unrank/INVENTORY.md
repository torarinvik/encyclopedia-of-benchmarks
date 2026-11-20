# Static source inventory

ABI: `myrvold_ruskey_permutation_unrank(input, length, output, capacity)`;
input `[n,rank]`, output little-endian signed-i64 permutation labels, maximum
output 64 bytes, workspace cap 256 bytes. See [`README.md`](README.md).

| Language | Source |
| --- | --- |
| C | [`c/m/myrvold_ruskey_permutation_unrank.c`](../../../c/m/myrvold_ruskey_permutation_unrank.c) |
| C3 | [`c3/m/myrvold_ruskey_permutation_unrank.c3`](../../../c3/m/myrvold_ruskey_permutation_unrank.c3) |
| C++ | [`cpp/m/myrvold_ruskey_permutation_unrank.cpp`](../../../cpp/m/myrvold_ruskey_permutation_unrank.cpp) |
| Elisa | [`elisa/m/myrvold_ruskey_permutation_unrank.elisa`](../../../elisa/m/myrvold_ruskey_permutation_unrank.elisa) |
| Mojo | [`mojo/m/myrvold_ruskey_permutation_unrank.mojo`](../../../mojo/m/myrvold_ruskey_permutation_unrank.mojo) |
| Nim | [`nim/m/myrvold_ruskey_permutation_unrank.nim`](../../../nim/m/myrvold_ruskey_permutation_unrank.nim) |
| Odin | [`odin/m/myrvold_ruskey_permutation_unrank.odin`](../../../odin/m/myrvold_ruskey_permutation_unrank.odin) |
| Rust | [`rust/m/myrvold_ruskey_permutation_unrank.rs`](../../../rust/m/myrvold_ruskey_permutation_unrank.rs) |
| V | [`v/m/myrvold_ruskey_permutation_unrank.v`](../../../v/m/myrvold_ruskey_permutation_unrank.v) |
| Zig | [`zig/m/myrvold_ruskey_permutation_unrank.zig`](../../../zig/m/myrvold_ruskey_permutation_unrank.zig) |

The workload, primary and independent references, package rights note, and
static checker are listed in [`INVENTORY.json`](INVENTORY.json). The
`i64_array_bytes_output` runner/verifier and catalog are integrated. No source
has been compiled or executed.
