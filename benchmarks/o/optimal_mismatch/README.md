# Optimal Mismatch string search

This package implements Sunday’s Optimal Mismatch exact matcher. It orders the
pattern positions by increasing frequency in the text, breaking frequency ties
by scanning the rightmost pattern position first. At each alignment it compares
in that order and advances by the larger of the adapted good-suffix shift and
the Quick Search lookahead-byte shift.

## Contract

- ABI: `i64_array_scalar`; symbol: `optimal_mismatch`.
- Input: `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
- Text length is 0 through 256; pattern length is 1 through 16; the packed
  frame contains exactly `2 + text_length + pattern_length` signed 64-bit values.
- Bytes must be ASCII values 0 through 127. Return the first matching
  zero-based byte offset, or `-1` when absent. Null input, malformed framing,
  out-of-range lengths, or invalid bytes return `-2`.
- Maximum valid and parseable frame length: 274 values.

The Quick Search table stores `m - last_position(byte)`, or `m + 1` when the
byte is absent from the pattern. The adapted good-suffix table is indexed by
the number of successfully compared frequency-ordered positions. A candidate
positive shift must preserve every previous equality under overlap and must
place a pattern byte different from the mismatching pattern byte beneath the
known mismatch. The search applies the larger table entry. A window ending at
the end of the text has no lookahead byte and terminates after a mismatch.

This bounded clean-room construction checks candidate shifts directly, so
preprocessing takes O(n + 128 + m^3) time and O(128 + m) space; the search takes
O(nm) worst-case time.

## Distinctions

Quick Search alone uses a fixed comparison order and only the lookahead-byte
shift. Horspool uses a byte aligned with the end of the current window.
Optimal Mismatch combines a frequency-ordered scan with both Quick Search and
an adapted good-suffix shift. The independent reference checks windows
directly and does not use either shift table.

## Sources

- [NIST DADS: Optimal mismatch](https://xlinux.nist.gov/dads/HTML/optimalMismatch.html)
- [Charras and Lecroq: Optimal Mismatch algorithm](https://www-igm.univ-mlv.fr/~lecroq/string/node28.html)

## Package files

- [Primary frequency-ordered reference](primary_oracle.py)
- [Independent direct-window reference](independent_oracle.py)
- [Workload](workload.json)
- [Rights and provenance](RIGHTS.md)
- [Static inventory](check_inventory.py)

## Language ports

| Language | File |
|---|---|
| C | [optimal_mismatch.c](../../../c/o/optimal_mismatch.c) |
| C3 | [optimal_mismatch.c3](../../../c3/o/optimal_mismatch.c3) |
| C++ | [optimal_mismatch.cpp](../../../cpp/o/optimal_mismatch.cpp) |
| Elisa | [optimal_mismatch.elisa](../../../elisa/o/optimal_mismatch.elisa) |
| Mojo | [optimal_mismatch.mojo](../../../mojo/o/optimal_mismatch.mojo) |
| Nim | [optimal_mismatch.nim](../../../nim/o/optimal_mismatch.nim) |
| Odin | [optimal_mismatch.odin](../../../odin/o/optimal_mismatch.odin) |
| Rust | [optimal_mismatch.rs](../../../rust/o/optimal_mismatch.rs) |
| V | [optimal_mismatch.v](../../../v/o/optimal_mismatch.v) |
| Zig | [optimal_mismatch.zig](../../../zig/o/optimal_mismatch.zig) |

No programs, scripts, checkers, tests, builds, compilers, or benchmarks were run.
