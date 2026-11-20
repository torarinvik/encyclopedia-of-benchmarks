# Not So Naive string search

This profile returns the first exact match of a byte pattern in a byte text.
It selects two shifts from the first two pattern bytes, compares byte 1 first,
then the remaining suffix, and checks byte 0 last. The preprocessing is `O(1)`;
the worst-case search time is `O(nm)` and the auxiliary space is `O(1)`.

## Contract

- ABI: `i64_array_scalar`; symbol: `not_so_naive_search`.
- Input layout: `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
- Text length is 0 through 512; pattern length is 2 through 64; the array must
  contain exactly `2 + text_length + pattern_length` values.
- Bytes are ASCII values 0 through 127. A valid call returns the first
  zero-based match offset, or `-1` when there is no match. Null input,
  invalid framing, or out-of-domain values return `-2`.

The two shift values depend only on whether the first two pattern bytes are
equal. When they are equal, a mismatch at text byte 1 advances two positions
and a completed attempt advances one. Otherwise those shifts are one and two.
For each attempt, the algorithm compares positions `1, 2, ..., m-1, 0`.

## Distinctions and source

This is a separate matching algorithm from direct brute-force search,
Horspool's bad-character table, KMP prefix fallback, and Crochemore–Perrin
Two-Way factorization. The bounded interface reports only the earliest match,
which makes the shift behavior suitable for a compact cross-language profile.

The algorithm description is documented by NIST's [Not So Naive entry](https://xlinux.nist.gov/dads/HTML/notsonaive.html)
and Charras and Lecroq's [exact string matching reference](https://ligm.univ-eiffel.fr/~lecroq/string/node13.html).
Only the algorithm description is used; no source code or sample text is copied.

The primary reference follows the two-shift search. The independent reference
checks every candidate window left to right. `workload.json` includes both
shift cases, overlaps, empty text, malformed frames, and byte boundaries.

## Language ports

| Language | Source |
|---|---|
| C | [not_so_naive_search.c](../../../c/n/not_so_naive_search.c) |
| C3 | [not_so_naive_search.c3](../../../c3/n/not_so_naive_search.c3) |
| C++ | [not_so_naive_search.cpp](../../../cpp/n/not_so_naive_search.cpp) |
| Elisa | [not_so_naive_search.elisa](../../../elisa/n/not_so_naive_search.elisa) |
| Mojo | [not_so_naive_search.mojo](../../../mojo/n/not_so_naive_search.mojo) |
| Nim | [not_so_naive_search.nim](../../../nim/n/not_so_naive_search.nim) |
| Odin | [not_so_naive_search.odin](../../../odin/n/not_so_naive_search.odin) |
| Rust | [not_so_naive_search.rs](../../../rust/n/not_so_naive_search.rs) |
| V | [not_so_naive_search.v](../../../v/n/not_so_naive_search.v) |
| Zig | [not_so_naive_search.zig](../../../zig/n/not_so_naive_search.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
