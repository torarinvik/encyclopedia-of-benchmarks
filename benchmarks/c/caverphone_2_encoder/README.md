# Caverphone 2.0 encoder

This byte-output profile maps one ASCII name to its ten-byte Caverphone 2.0
phonetic code. It uses the updated general English matching rules rather than
the original regional Caverphone rules. It is distinct from the local NYSIIS
and Soundex encoders: those produce different codes from different rewrite
systems.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `caverphone_2_encoder`.
- Input: `[length, ASCII letters...]`; `length` is in `0..64` and the array
  must contain exactly `length+1` signed 64-bit words.
- ASCII upper- and lowercase letters are accepted. Empty text is valid and
  encodes to ten `1` bytes. Other bytes, malformed frames, null input, or
  trailing words return `-1`.
- Success returns exactly ten uppercase ASCII bytes in the set
  `AFKLMNPRSTWY1`, without a terminator. A null output pointer or capacity
  below ten returns `-2` and writes no bytes.
- Maximum valid and parseable input-array lengths are 65 and 67 words.

## Algorithm and cost

Normalize to lowercase ASCII, discard no characters (the bounded input
already contains letters only), remove a trailing `e`, and apply the ordered
Caverphone 2.0 start/end substitutions, consonant rewrites, vowel/y rules,
phoneme-group compression, and marker cleanup. Append `1` padding and take the
first ten characters. The number of transformation passes is fixed, so time
and temporary space are both `O(L)` for input length `L<=64`.

The primary reference applies the ordered rules as anchored and global
substitutions. The independent reference applies the same published rule order
using a separate character-sequence rewrite routine. Fixtures include empty
text, vowel/y starts, grouped consonants, and leading/end marker cases.

## Provenance and relation to nearby algorithms

The [NIST Dictionary of Algorithms and Data Structures Caverphone entry](https://xlinux.nist.gov/dads/HTML/caverphone.html)
identifies the algorithm as an English phonetic encoder and distinguishes the
updated 2.0 profile from the original regional encoder. The specification is
David Hood, [*Caverphone Revisited*, Technical Paper CTP150804](https://caversham.otago.ac.nz/files/working/ctp150804.pdf),
University of Otago, 2004. Apache Commons Codec documents its Caverphone 2.0
implementation and points to Hood's specification. Only algorithm descriptions
were used; no implementation, sample, or test data was copied.

Unlike the Caverphone family, `nysiis_encoder` and `soundex_encoder` are
different phonetic coding algorithms. The NATO-style
`phonetic_alphabet_converter` spells characters and is not a phonetic matching
algorithm.

## Language ports

| Language | Source |
|---|---|
| C | [caverphone_2_encoder.c](../../../c/c/caverphone_2_encoder.c) |
| C3 | [caverphone_2_encoder.c3](../../../c3/c/caverphone_2_encoder.c3) |
| C++ | [caverphone_2_encoder.cpp](../../../cpp/c/caverphone_2_encoder.cpp) |
| Elisa | [caverphone_2_encoder.elisa](../../../elisa/c/caverphone_2_encoder.elisa) |
| Mojo | [caverphone_2_encoder.mojo](../../../mojo/c/caverphone_2_encoder.mojo) |
| Nim | [caverphone_2_encoder.nim](../../../nim/c/caverphone_2_encoder.nim) |
| Odin | [caverphone_2_encoder.odin](../../../odin/c/caverphone_2_encoder.odin) |
| Rust | [caverphone_2_encoder.rs](../../../rust/c/caverphone_2_encoder.rs) |
| V | [caverphone_2_encoder.v](../../../v/caverphone_2_encoder.v) |
| Zig | [caverphone_2_encoder.zig](../../../zig/c/caverphone_2_encoder.zig) |

`check_inventory.py` records the static package inventory. No programs,
scripts, tests, checkers, builds, compilers, profilers, or benchmarks have been
run.
