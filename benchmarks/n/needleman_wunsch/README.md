# Needleman–Wunsch alignment score

Compute the optimal global alignment score for two bounded uppercase ASCII sequences using match, mismatch, and linear gap scores. The pinned Java source returns the dynamic-programming score; this benchmark does not reconstruct alignment strings.

## Contract

- The `i64_array_scalar` input is `[len_a, len_b, match_score, mismatch_score, gap_score, chars_a..., chars_b...]`.
- Sequence lengths are 0 through 128; characters are uppercase ASCII. Match score is 0 through 10; mismatch and gap scores are -10 through 0.
- The result uses the standard global alignment recurrence with gap initialization on the first row and column. Malformed input returns `INT64_MIN`, outside the valid score range.

[`workload.json`](workload.json) includes empty sequences, mismatch and gap cases, a classic alignment example, and the maximum sequence length.

## Implementations

- C: [`c/n/needleman_wunsch.c`](../../../c/n/needleman_wunsch.c)
- C3: [`c3/n/needleman_wunsch.c3`](../../../c3/n/needleman_wunsch.c3)
- C++: [`cpp/n/needleman_wunsch.cpp`](../../../cpp/n/needleman_wunsch.cpp)
- Elisa: [`elisa/n/needleman_wunsch.elisa`](../../../elisa/n/needleman_wunsch.elisa)
- Nim: [`nim/n/needleman_wunsch.nim`](../../../nim/n/needleman_wunsch.nim)
- Odin: [`odin/n/needleman_wunsch.odin`](../../../odin/n/needleman_wunsch.odin)
- Rust: [`rust/n/needleman_wunsch.rs`](../../../rust/n/needleman_wunsch.rs)
- V: [`v/n/needleman_wunsch.v`](../../../v/n/needleman_wunsch.v)
- Zig: [`zig/n/needleman_wunsch.zig`](../../../zig/n/needleman_wunsch.zig)

The benchmark follows the pinned [Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/NeedlemanWunsch.java), which scores global alignments using a two-dimensional dynamic-programming table. The ports retain the recurrence with a rolling row.
