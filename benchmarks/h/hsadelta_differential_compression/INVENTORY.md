# Static inventory

Package: `hsadelta_differential_compression`  
ABI: `i64_array_bytes_output`  
Exported symbol: `hsadelta_differential_compression`

Input is `[reference_length, version_length, block_size, reference_bytes..., version_bytes...]`.
Both byte strings are bounded by 32 bytes, block size is 2–4, and byte values
are 0–255. Maximum valid input length is 67 i64 words; the parser bound is 68.
Malformed input returns `-1`. Output is a little-endian i64 byte stream with
INSERT `(0, length, bytes...)` and COPY `(1, reference_offset, length)` commands.
Maximum output is 912 bytes; null or undersized output returns `-2` without
writes. The zero-byte result permits a null output pointer. Workspace metadata
is 2,048 bytes.

The fixed-block-size variant uses base-257 byte-block fingerprints and a
suffix array over aligned reference blocks. Prefix intervals locate maximum
matching depth; exact extension and a deterministic tie rule produce the
delta. The independent reference scans aligned reference blocks directly and
does not use hashes or a suffix array. The proportional-block variant and the
paper's quick-index/pointer-array/packed-hash accelerators are excluded.

Source audit: NIST DADS HsaDelta entry and Agarwal et al., “An approximation
to the greedy algorithm for differential compression,” IBM JRD 50(1), 149–166
(2006), DOI [10.1147/rd.501.0149](https://doi.org/10.1147/rd.501.0149).
The port uses the algorithm description only; implementation is clean-room.

| Language | Port |
|---|---|
| C | [`c/h/hsadelta_differential_compression.c`](../../../c/h/hsadelta_differential_compression.c) |
| C3 | [`c3/h/hsadelta_differential_compression.c3`](../../../c3/h/hsadelta_differential_compression.c3) |
| C++ | [`cpp/h/hsadelta_differential_compression.cpp`](../../../cpp/h/hsadelta_differential_compression.cpp) |
| Elisa | [`elisa/h/hsadelta_differential_compression.elisa`](../../../elisa/h/hsadelta_differential_compression.elisa) |
| Mojo | [`mojo/h/hsadelta_differential_compression.mojo`](../../../mojo/h/hsadelta_differential_compression.mojo) |
| Nim | [`nim/h/hsadelta_differential_compression.nim`](../../../nim/h/hsadelta_differential_compression.nim) |
| Odin | [`odin/h/hsadelta_differential_compression.odin`](../../../odin/h/hsadelta_differential_compression.odin) |
| Rust | [`rust/h/hsadelta_differential_compression.rs`](../../../rust/h/hsadelta_differential_compression.rs) |
| V | [`v/h/hsadelta_differential_compression.v`](../../../v/h/hsadelta_differential_compression.v) |
| Zig | [`zig/h/hsadelta_differential_compression.zig`](../../../zig/h/hsadelta_differential_compression.zig) |

This is a source inventory only. No package checker, executable, compiler, or
test has been run.
