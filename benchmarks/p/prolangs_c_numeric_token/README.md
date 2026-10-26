# Prolangs-C bounded numeric token

This package isolates the numeric-literal path in `Prolangs-C/compiler/lexer.c::Number` from the toy compiler's symbol table, parser, and emitter. It preserves the source's `NUM` versus `RNUM` token codes, integer attribute, and binary32 real attribute. The implementation is clean-room and does not copy upstream code.

## Contract

The `prolangs_c_numeric_token` entry point uses the `i64_array_bytes_output` ABI. Input is one 1–24 byte ASCII numeric lexeme, encoded as one signed 64-bit value per byte. The bounded accepted profile is unsigned decimal integer or real literal with a decimal point and/or `e`/`E` exponent; a sign is permitted only immediately after the exponent marker. Integer part is at most 2,147,483,647, there are at most six fractional digits, and exponent magnitude is at most six. Unsupported/malformed lexemes return `-1`. Output capacity below 12 bytes or a null output pointer returns `-2` after input validation; success returns 12.

Output is three little-endian signed 32-bit words: source token (`256` for integer `NUM`, `2001` for real `RNUM`), integer attribute, and the raw IEEE-754 binary32 bits of the real attribute. Integer literals have a zero real attribute. Real arithmetic follows `Number`'s operation order: convert the fractional integer to binary32, repeatedly divide by ten while at least one, divide once for each omitted leading fractional zero, add the integer part, then apply the exponent one binary32 multiply/divide by ten at a time. A bare `.` follows the source routine and produces `RNUM` zero. Decimal/exponent spellings are intentionally bounded to avoid C `scanf` overflow and source undefined behavior.

## Provenance and rights

Source inspected at pinned `lac-dcc/Benchmarks` revision `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, path `Prolangs-C/compiler/lexer.c`, function `Number`; launcher `Prolangs-C/compiler/info.sh` builds the compiler from the lexer, parser, symbol, emitter, initialization, and error modules. The pinned directory has no explicit license or redistribution grant. This package contains independently written implementations based on the described observable behavior and does not copy or translate source text. No upstream source code is redistributed.

The executable `compiler` is a whole educational compiler workload and is not claimed as covered by this isolated numeric-token profile.

## Workload and ports

See [`workload.json`](workload.json) and the independent reference model [`benchmarks/prolangs_c_numeric_token_oracle.py`](../../prolangs_c_numeric_token_oracle.py).

| Language | Port |
| --- | --- |
| C | [`c/p/prolangs_c_numeric_token.c`](../../../c/p/prolangs_c_numeric_token.c) |
| C3 | [`c3/p/prolangs_c_numeric_token.c3`](../../../c3/p/prolangs_c_numeric_token.c3) |
| C++ | [`cpp/p/prolangs_c_numeric_token.cpp`](../../../cpp/p/prolangs_c_numeric_token.cpp) |
| Elisa | [`elisa/p/prolangs_c_numeric_token.elisa`](../../../elisa/p/prolangs_c_numeric_token.elisa) |
| Nim | [`nim/p/prolangs_c_numeric_token.nim`](../../../nim/p/prolangs_c_numeric_token.nim) |
| Odin | [`odin/p/prolangs_c_numeric_token.odin`](../../../odin/p/prolangs_c_numeric_token.odin) |
| Rust | [`rust/p/prolangs_c_numeric_token.rs`](../../../rust/p/prolangs_c_numeric_token.rs) |
| V | [`v/p/prolangs_c_numeric_token.v`](../../../v/p/prolangs_c_numeric_token.v) |
| Zig | [`zig/p/prolangs_c_numeric_token.zig`](../../../zig/p/prolangs_c_numeric_token.zig) |

All ports are clean-room implementations. The upstream source's license status remains unresolved; this note is not a license grant for the original compiler.
