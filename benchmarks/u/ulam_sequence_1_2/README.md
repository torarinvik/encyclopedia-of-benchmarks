# U(1,2) Ulam sequence

This package returns the one-based kth term of the classical U(1,2) Ulam sequence. It fixes the initial terms to `1, 2`; each later term is the least larger integer that has exactly one representation as a sum of two distinct earlier terms.

## Contract

- ABI: `int64_t ulam_sequence_1_2(const int64_t *input, size_t length)`.
- Input frame: exactly `[k]`, with `1 <= k <= 14`; the parseable frame cap is two words so one trailing word is rejected explicitly.
- Return `U_k`. Invalid or null input returns `-1`.
- This bounded profile stops at the published fourteenth term, `38`. Candidate search is capped at `64`; a failed scan returns `-1`.
- The primary stores pair-sum representation counts saturated at two. It tests candidates in increasing order, then adds the new term's sums with each earlier term.
- The independent reference recomputes all `i<j` representations for each candidate from scratch.

The prefix is `1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, 28, 36, 38`. Candidates 5 and 7 are rejected because each has two representations from distinct earlier terms. Pair sums in this prefix are at most `38+36=74`. Native primary state is a 14-element i64 term array plus a 75-element i64 count array (712 bytes) and scalar locals, within the 1,024-byte workspace cap. The candidate loop examines at most 64 integers per append; the independent method checks fewer than 60,000 pairs over the full bounded prefix.

This differs from [`mian_chowla_sequence`](../../m/mian_chowla_sequence/README.md): Mian–Chowla enforces globally distinct unordered pair sums including repeated terms, while Ulam uses only distinct prior indices and selects sums with exactly one representation. It also differs from an Ulam spiral, which is a geometric visualization of integer placement.

## RosettaCodeData title-band cross-check

The title-only 38–36 audit also encountered Padovan sequence, multiplicative order, Cipolla's algorithm, Pandigital Prime, N-smooth numbers, and Ulam spiral. The first four map to local `padovan_sequence`, `multiplicative_order`, `cipolla_modular_square_root`, and `problem41` profiles, respectively. The local `hamming_numbers` profile covers the canonical 5-smooth specialization of N-smooth numbers; a general smoothness-parameter contract is broader and is not claimed as an exact duplicate here. Ulam spiral is a visualization task and is excluded from this sequence package. The Ulam numbers title maps to the distinct U(1,2) recurrence implemented here.

## Source and provenance

The [MathWorld Ulam Sequence definition](https://mathworld.wolfram.com/UlamSequence.html) specifies U(u,v) by choosing the least integer expressible uniquely as a sum of two distinct earlier terms and lists the U(1,2) prefix. [OEIS A002858](https://oeis.org/A002858) supplies the accepted sequence definition and additional terms. The pinned [RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) was used only for title discovery (“Ulam numbers”). No task text, code, examples, or tests were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/u/ulam_sequence_1_2.c`](../../../c/u/ulam_sequence_1_2.c) |
| C3 | [`c3/u/ulam_sequence_1_2.c3`](../../../c3/u/ulam_sequence_1_2.c3) |
| C++ | [`cpp/u/ulam_sequence_1_2.cpp`](../../../cpp/u/ulam_sequence_1_2.cpp) |
| Elisa | [`elisa/u/ulam_sequence_1_2.elisa`](../../../elisa/u/ulam_sequence_1_2.elisa) |
| Mojo | [`mojo/u/ulam_sequence_1_2.mojo`](../../../mojo/u/ulam_sequence_1_2.mojo) |
| Nim | [`nim/u/ulam_sequence_1_2.nim`](../../../nim/u/ulam_sequence_1_2.nim) |
| Odin | [`odin/u/ulam_sequence_1_2.odin`](../../../odin/u/ulam_sequence_1_2.odin) |
| Rust | [`rust/u/ulam_sequence_1_2.rs`](../../../rust/u/ulam_sequence_1_2.rs) |
| V | [`v/u/ulam_sequence_1_2.v`](../../../v/u/ulam_sequence_1_2.v) |
| Zig | [`zig/u/ulam_sequence_1_2.zig`](../../../zig/u/ulam_sequence_1_2.zig) |

`workload.json` defines the bounded fixtures and ABI framing. `verify_workload.py` compares its cases with both references; `check_inventory.py` checks package artifacts, source paths, exported symbol names, null guards, and provenance links. These source-level helpers were drafted but not run.
