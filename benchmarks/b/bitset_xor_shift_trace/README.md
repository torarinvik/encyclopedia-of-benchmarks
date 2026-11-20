# Packed bitset XOR-shift trace

Apply a sequence of signed-direction shift-XOR updates to one bounded bit vector and record its population count after every update. This is a repeated mutable bitset kernel, distinct from shifting one machine word, querying a packed set, maintaining an XOR basis, or convolving two vectors.

## Contract

The `i64_array_bytes_output` frame is `[n, q, packed_words..., shifts...]`. Use `1<=n<=4096`, `0<=q<=64`, and exactly `ceil(n/64)` packed words. Each input word is a signed i64 carrying its full two's-complement 64-bit pattern. Word 0 contains logical bits 0 through 63, least-significant bit first; logical bit 0 is the rightmost bit of the corresponding binary string. Unused high bits in the final word must be zero. Each shift `d` satisfies `-(n-1)<=d<=n-1`.

For `d>0`, update `s := s XOR (s >> d)`. For `d<0`, update `s := s XOR (s << abs(d))`, truncating to the `n` logical bits. For `d=0`, the shift is the identity and the XOR therefore clears the vector. Record the number of set bits after each operation as a little-endian signed i32. Null or malformed input returns `-1`; null or short output returns `-2` after input validation. A valid zero-operation trace returns zero bytes and permits a null output pointer. Errors leave the output untouched.

The maximum valid and parseable input lengths are 130 and 131 i64 words. Output uses at most 256 bytes. Workspace is bounded at 1,024 bytes: 64 packed u64 words (512 bytes), 64 staged i32 counts (256 bytes), plus bounded control state. Ports update packed words in a safe direction so source words are read before any shift-dependent overwrite.

## References and provenance

The Library Checker [Bitset XOR Shift proposal #1362](https://github.com/yosupo06/library-checker-problems/issues/1362) was used as a discovery lead and to identify the operation family. The benchmark pins the bitwise recurrence above and defines its own packed-word ABI, size limits, output format, and zero-shift behavior. The primary reference uses packed-word shifts; the independent reference updates a logical Boolean array bit by bit. The contract, fixtures, and all ports are original. No issue text, sample, code, or test data is reused; see [`RIGHTS.md`](RIGHTS.md).

## Package files

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), [`independent_oracle.py`](independent_oracle.py), [`verify_workload.py`](verify_workload.py), [`INVENTORY.json`](INVENTORY.json), and [`check_inventory.py`](check_inventory.py). The package-local checkers are static and have not been run.

The bounded workload is registered with the shared `i64_array_bytes_output` runner and verifier, and the algorithm is listed in [CATALOG](../../../CATALOG.md). No programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks were run.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/b/bitset_xor_shift_trace.c`](../../../c/b/bitset_xor_shift_trace.c) |
| C3 | [`c3/b/bitset_xor_shift_trace.c3`](../../../c3/b/bitset_xor_shift_trace.c3) |
| C++ | [`cpp/b/bitset_xor_shift_trace.cpp`](../../../cpp/b/bitset_xor_shift_trace.cpp) |
| Elisa | [`elisa/b/bitset_xor_shift_trace.elisa`](../../../elisa/b/bitset_xor_shift_trace.elisa) |
| Mojo | [`mojo/b/bitset_xor_shift_trace.mojo`](../../../mojo/b/bitset_xor_shift_trace.mojo) |
| Nim | [`nim/b/bitset_xor_shift_trace.nim`](../../../nim/b/bitset_xor_shift_trace.nim) |
| Odin | [`odin/b/bitset_xor_shift_trace.odin`](../../../odin/b/bitset_xor_shift_trace.odin) |
| Rust | [`rust/b/bitset_xor_shift_trace.rs`](../../../rust/b/bitset_xor_shift_trace.rs) |
| V | [`v/b/bitset_xor_shift_trace.v`](../../../v/b/bitset_xor_shift_trace.v) |
| Zig | [`zig/b/bitset_xor_shift_trace.zig`](../../../zig/b/bitset_xor_shift_trace.zig) |
