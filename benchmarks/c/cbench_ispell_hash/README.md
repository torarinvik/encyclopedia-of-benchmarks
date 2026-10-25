# cBench Ispell word hash

This package isolates the small `hash` helper from the pinned cBench Ispell source. It does not port dictionary lookup, affix processing, file I/O, or the full Ispell launcher.

## Contract

Each port exports `cbench_ispell_hash` using the `i64_array_scalar` shape. Input is `[table_size, byte_0, ..., byte_(n-1)]`; a one-element array represents the empty word. `table_size` must be 1 through 2,147,483,647. The word is at most 64 bytes; bytes must be non-NUL ASCII values 1 through 127. Invalid input returns `-1`. Valid input returns the hash bucket in `[0, table_size)`.

The source's `ICHAR_IS_CHAR` configuration packs the first four upper-converted characters in order, then rotates the 32-bit state left by five and XORs each remaining upper-converted character. This profile models the English ASCII upper-conversion behavior: `a` through `z` map to `A` through `Z`; other ASCII bytes are unchanged. The final 32-bit unsigned state is reduced modulo `table_size`. The explicit ASCII boundary avoids dependence on Ispell's runtime character-set conversion table.

## Provenance and rights

- Pinned repository: [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks)
- Commit: `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`
- Launcher: [`cBench/office_ispell/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ispell/src/info.sh) (builds the complete Ispell executable from all C files)
- Helper: [`cBench/office_ispell/src/hash.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ispell/src/hash.c), symbol `hash`; the source attributes the algorithm to Ian Dall with modifications by Geoff Kuenning.

The helper permits use, copying, modification, and redistribution subject to the complete copyright, conditions, advertising acknowledgment, endorsement restriction, and disclaimer reproduced in [`LICENSE.txt`](LICENSE.txt). These ports are modified implementations; the source-code change condition is documented here. The separate dictionary data and complete Ispell behavior are outside this package.

## Workload and ports

[`workload.json`](workload.json) has casing, short-word, long-word, modulo, and malformed-input fixtures. [`cbench_ispell_hash_oracle.py`](../../cbench_ispell_hash_oracle.py) is the independent scalar model.

| Language | Port |
|---|---|
| C | [`c/c/cbench_ispell_hash.c`](../../../c/c/cbench_ispell_hash.c) |
| C3 | [`c3/c/cbench_ispell_hash.c3`](../../../c3/c/cbench_ispell_hash.c3) |
| C++ | [`cpp/c/cbench_ispell_hash.cpp`](../../../cpp/c/cbench_ispell_hash.cpp) |
| Elisa | [`elisa/c/cbench_ispell_hash.elisa`](../../../elisa/c/cbench_ispell_hash.elisa) |
| Nim | [`nim/c/cbench_ispell_hash.nim`](../../../nim/c/cbench_ispell_hash.nim) |
| Odin | [`odin/c/cbench_ispell_hash.odin`](../../../odin/c/cbench_ispell_hash.odin) |
| Rust | [`rust/c/cbench_ispell_hash.rs`](../../../rust/c/cbench_ispell_hash.rs) |
| V | [`v/c/cbench_ispell_hash.v`](../../../v/c/cbench_ispell_hash.v) |
| Zig | [`zig/c/cbench_ispell_hash.zig`](../../../zig/c/cbench_ispell_hash.zig) |

No runtime or compiler verification is claimed.
