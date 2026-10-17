# Prüfer code

This package ports the pinned Rust module's Prüfer encoding and decoding for labeled trees. Both directions use the source's `BinaryHeap` max-first ordering: encoding removes the largest current leaf, while decoding removes the largest remaining label absent from the rest of the code. This differs from the common min-leaf convention.

## Contract

The `i64_array_bytes_output` input is `[mode, vertex_count, payload...]`, with canonical labels `0..vertex_count-1` and `vertex_count` at most 64.

- Mode `0` encodes a valid simple undirected tree. It takes exactly `vertex_count-1` edge pairs after the header (`2*vertex_count` i64 values total); each endpoint is a distinct in-range label, pairs are unique, and the graph is connected. The output is the `vertex_count-2` Prüfer labels as signed i64 little-endian values, without a header. A one- or two-vertex tree produces zero output bytes and succeeds even with a null output pointer and zero capacity.
- Mode `1` decodes a sequence of exactly `vertex_count-2` labels, each in range. It requires 2 through 64 vertices. The output is `[edge_count, u_0, v_0, ...]`, where `edge_count=vertex_count-1` and each undirected edge has `u<v`; pairs are sorted lexicographically. Every item is a signed i64 little-endian value.

The maximum valid input is 128 i64 values; the parser cap is 129. Maximum output/workspace is 1,016 bytes for 64 vertices. Invalid mode, framing, labels, tree, or code returns `-1`. For nonempty output, a null pointer or short capacity returns `-2` without writes. Success returns bytes written.

The pinned source is TheAlgorithms/Rust, commit `650541d6244016117121870a3e672157bb65005d`, path `src/graph/prufer_code.rs`. See the [pinned source](https://github.com/TheAlgorithms/Rust/blob/650541d6244016117121870a3e672157bb65005d/src/graph/prufer_code.rs), [workload](workload.json), and [oracle](../../prufer_code_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/p/prufer_code.c |
| C3 | ../../../c3/p/prufer_code.c3 |
| C++ | ../../../cpp/p/prufer_code.cpp |
| Elisa | ../../../elisa/p/prufer_code.elisa |
| Nim | ../../../nim/p/prufer_code.nim |
| Odin | ../../../odin/p/prufer_code.odin |
| Rust | ../../../rust/p/prufer_code.rs |
| V | ../../../v/p/prufer_code.v |
| Zig | ../../../zig/p/prufer_code.zig |

Build and record with the shared ABI after serialized integration is complete:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm prufer_code --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm prufer_code
```
