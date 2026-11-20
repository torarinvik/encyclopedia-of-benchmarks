# Static package inventory

Algorithm: greedy left-to-right maximum matching over an ordered word dictionary

ABI: `i64_array_bytes_output`, symbol `maximum_matching_word_segmentation`

Input: `[text_length, dictionary_count, text_codes..., (word_length, word_codes...)*]`; text `0..=64`, dictionary `0..=16`, word length `1..=8`, lowercase ASCII codes `97..=122`; maximum valid/parseable input lengths are 210/211 i64 values.

Output: raw bytes `[token_count, token_id_0, ...]`; one-based dictionary word IDs identify matches and zero identifies one unmatched character. Maximum output is 65 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.

| Language | Source |
| --- | --- |
| C | [`c/m/maximum_matching_word_segmentation.c`](../../../c/m/maximum_matching_word_segmentation.c) |
| C3 | [`c3/m/maximum_matching_word_segmentation.c3`](../../../c3/m/maximum_matching_word_segmentation.c3) |
| C++ | [`cpp/m/maximum_matching_word_segmentation.cpp`](../../../cpp/m/maximum_matching_word_segmentation.cpp) |
| Elisa | [`elisa/m/maximum_matching_word_segmentation.elisa`](../../../elisa/m/maximum_matching_word_segmentation.elisa) |
| Mojo | [`mojo/m/maximum_matching_word_segmentation.mojo`](../../../mojo/m/maximum_matching_word_segmentation.mojo) |
| Nim | [`nim/m/maximum_matching_word_segmentation.nim`](../../../nim/m/maximum_matching_word_segmentation.nim) |
| Odin | [`odin/m/maximum_matching_word_segmentation.odin`](../../../odin/m/maximum_matching_word_segmentation.odin) |
| Rust | [`rust/m/maximum_matching_word_segmentation.rs`](../../../rust/m/maximum_matching_word_segmentation.rs) |
| V | [`v/m/maximum_matching_word_segmentation.v`](../../../v/m/maximum_matching_word_segmentation.v) |
| Zig | [`zig/m/maximum_matching_word_segmentation.zig`](../../../zig/m/maximum_matching_word_segmentation.zig) |

Support files: [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), [`independent_oracle.py`](independent_oracle.py), [`inventory.json`](inventory.json), [`check_inventory.py`](check_inventory.py), and [`RIGHTS.md`](RIGHTS.md).

Static inventory metadata and validator source are present. No executable validation was run.
