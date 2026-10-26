# Prolangs-C loader relocation field addition

This package isolates `memory.c::ADD_INT_TO_LOC`, the SIC/XE loader operation that adds a relocation delta to a stored big-endian field. It is distinct from general radix conversion: the operation reads a fixed-width memory field, adds the relocation shift, and writes exactly that field width back.

## Contract

The `prolangs_c_loader_relocation_add` entry point uses the `i64_array_bytes_output` ABI with input `[half_bytes, delta, byte_0, ...]`. `half_bytes` is 1 through 6; the source rounds odd half-byte counts up to an even count, so the touched byte width is `ceil(half_bytes/2)`. The bytes encode one unsigned big-endian field. `delta` is in `[-65535,65535]`, and the mathematical adjusted value must be nonnegative. The input length must be exactly two words plus the touched byte count; byte values are 0 through 255.

The value is interpreted as an unsigned big-endian integer, the signed delta is added, and the result is formatted to exactly `2*width` uppercase hexadecimal digits and stored as big-endian bytes. If the adjusted value exceeds the field width, the source formatter keeps the low field digits and reports a diagnostic; this package models the stored low-width result and omits that process message. Malformed input returns `-1`; insufficient output capacity or null output returns `-2` after input validation; success returns the number of bytes written (1 through 3).

## Provenance and rights

Pinned upstream: [`lac-dcc/Benchmarks` revision `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/loader), specifically `memory.c::ADD_INT_TO_LOC`, with formatting behavior from `convert.c::NUM_TO_STR` and `STR_TO_NUM`. The launcher is `Prolangs-C/loader/info.sh`. The source notice grants use on condition that its copyright notice remains; the exact William Landi 1991 notice is retained in [`LICENSE.txt`](LICENSE.txt) and each port. The implementations are independently written and redistribute no upstream source code.

The complete two-pass loader, object-record parser, symbol table, and memory-dump workload are outside this bounded helper profile.

## Files

- Independent oracle: [`benchmarks/prolangs_c_loader_relocation_add_oracle.py`](../../prolangs_c_loader_relocation_add_oracle.py)
- Workload: [`workload.json`](workload.json)

| Language | Port |
| --- | --- |
| C | [`c/p/prolangs_c_loader_relocation_add.c`](../../../c/p/prolangs_c_loader_relocation_add.c) |
| C3 | [`c3/p/prolangs_c_loader_relocation_add.c3`](../../../c3/p/prolangs_c_loader_relocation_add.c3) |
| C++ | [`cpp/p/prolangs_c_loader_relocation_add.cpp`](../../../cpp/p/prolangs_c_loader_relocation_add.cpp) |
| Elisa | [`elisa/p/prolangs_c_loader_relocation_add.elisa`](../../../elisa/p/prolangs_c_loader_relocation_add.elisa) |
| Nim | [`nim/p/prolangs_c_loader_relocation_add.nim`](../../../nim/p/prolangs_c_loader_relocation_add.nim) |
| Odin | [`odin/p/prolangs_c_loader_relocation_add.odin`](../../../odin/p/prolangs_c_loader_relocation_add.odin) |
| Rust | [`rust/p/prolangs_c_loader_relocation_add.rs`](../../../rust/p/prolangs_c_loader_relocation_add.rs) |
| V | [`v/p/prolangs_c_loader_relocation_add.v`](../../../v/p/prolangs_c_loader_relocation_add.v) |
| Zig | [`zig/p/prolangs_c_loader_relocation_add.zig`](../../../zig/p/prolangs_c_loader_relocation_add.zig) |
