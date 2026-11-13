# Rabin content-defined chunking (in progress)

This profile scans a byte sequence using a rolling polynomial fingerprint over
GF(2). It emits a boundary when the low three fingerprint bits are zero, and
also emits the final position if the last byte did not already cause a cut.
The rolling window continues across cuts. Unlike pattern search, the input
content determines the chunk boundaries.

The proposed `i64_array_bytes_output` input is `[n, byte_0, ..., byte_(n-1)]`,
where `0 <= n <= 64`, each byte is in `0..255`, and the frame length is
exactly `n+1`. Use polynomial `x^16 + x^12 + x^3 + x + 1` (`0x1100b`) and a
four-byte window. Before four bytes have arrived, use the available prefix.
Interpret each window as a big-endian polynomial bit string and reduce it
modulo the polynomial. Emit each nonzero, one-based boundary as an unsigned
byte in increasing order. An empty input emits no bytes. The return value is
the byte count; invalid input returns `-1`, and a null output or insufficient
capacity returns `-2`, including for an empty result. Errors do not write.

The intended implementation precomputes the contribution of each outgoing
byte and updates the fingerprint in constant time per byte. It takes O(n)
time after a fixed-size table initialization, with O(1) bounded auxiliary
space. An independent oracle should reduce each window from scratch.

The [PARSEC report](https://www.cs.princeton.edu/techreports/2010/890.pdf)
identifies low-bit Rabin-fingerprint fragmentation as a Dedup kernel. A
[USENIX study](https://www.usenix.org/legacy/events/usenix04/tech/general/full_papers/policroniades/policroniades_html/index.html)
describes sliding-window polynomial fingerprints for content-defined chunks.
This is a deliberately small independent profile, not a claim of exact PARSEC
parameters or complete Dedup behavior. No source text or code is reused.

**Status:** two oracle drafts, a workload, ten language drafts and byte-output
suite registration are present. All remain unexecuted and require validation.
The suite's package validation checks each draft's path and exported name, and
the workload includes a nonzero byte leaving the window after four positions.

| Language | Draft |
| --- | --- |
| C | [`c/r/rabin_content_defined_chunking.c`](../../../c/r/rabin_content_defined_chunking.c) |
| C3 | [`c3/r/rabin_content_defined_chunking.c3`](../../../c3/r/rabin_content_defined_chunking.c3) |
| C++ | [`cpp/r/rabin_content_defined_chunking.cpp`](../../../cpp/r/rabin_content_defined_chunking.cpp) |
| Elisa | [`elisa/r/rabin_content_defined_chunking.elisa`](../../../elisa/r/rabin_content_defined_chunking.elisa) |
| Mojo | [`mojo/r/rabin_content_defined_chunking.mojo`](../../../mojo/r/rabin_content_defined_chunking.mojo) |
| Nim | [`nim/r/rabin_content_defined_chunking.nim`](../../../nim/r/rabin_content_defined_chunking.nim) |
| Odin | [`odin/r/rabin_content_defined_chunking.odin`](../../../odin/r/rabin_content_defined_chunking.odin) |
| Rust | [`rust/r/rabin_content_defined_chunking.rs`](../../../rust/r/rabin_content_defined_chunking.rs) |
| V | [`v/r/rabin_content_defined_chunking.v`](../../../v/r/rabin_content_defined_chunking.v) |
| Zig | [`zig/r/rabin_content_defined_chunking.zig`](../../../zig/r/rabin_content_defined_chunking.zig) |
