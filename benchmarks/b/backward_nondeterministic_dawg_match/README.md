# Backward nondeterministic DAWG matching

This draft searches for the first exact occurrence with backward nondeterministic
DAWG matching (BNDM). For each candidate window it scans from right to left,
simulating a reversed-pattern automaton with a bit mask. Surviving prefix states
determine the next window shift. This differs from the existing forward
shift-OR Bitap search and from the comparison-based Horspool and Two-Way
searches.

The `i64_array_scalar` input is `[text_length, pattern_length, text..., pattern...]`.
Text and pattern contain lowercase ASCII bytes encoded as i64 values. Text
length is in `0..4096` and pattern length in `0..63`; the frame length must
equal `2 + text_length + pattern_length`. Return the first zero-based match,
zero for an empty pattern, -1 if no match exists, and -2 for null or malformed
input. All bytes are validated even for an empty or overlong pattern.

Preprocessing takes `O(m + alphabet)` time and `O(alphabet)` words. The
worst-case search takes `O(n*m)` time, with up to `m` backward steps per
window; `m <= 63` fits in one 64-bit word. The selected limits match the
existing Bitap contract to make the algorithms comparable.

The algorithm is described by Navarro and Raffinot in [A Bit-parallel Approach
to Suffix Automata](https://users.dcc.uchile.cl/~gnavarro/abstracts/cpm98.html).
Only the algorithm idea and bibliographic facts were used; the implementations
and contract are independently written. Drafts for C, C3, C++, Elisa, Mojo,
Nim, Odin, Rust, V and Zig, two references, initial workload cases, and scalar
suite registration are present. The verifier source specifies exhaustive
short binary-alphabet inputs, word-boundary patterns, maximum-length input,
and null inputs. The Elisa draft uses a bounded input view and indexed arrays.
All ports and suite integration remain uncompiled and unexecuted.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/b/backward_nondeterministic_dawg_match.c) |
| C3 | [C3](../../../c3/b/backward_nondeterministic_dawg_match.c3) |
| C++ | [C++](../../../cpp/b/backward_nondeterministic_dawg_match.cpp) |
| Elisa | [Elisa](../../../elisa/b/backward_nondeterministic_dawg_match.elisa) |
| Mojo | [Mojo](../../../mojo/b/backward_nondeterministic_dawg_match.mojo) |
| Nim | [Nim](../../../nim/b/backward_nondeterministic_dawg_match.nim) |
| Odin | [Odin](../../../odin/b/backward_nondeterministic_dawg_match.odin) |
| Rust | [Rust](../../../rust/b/backward_nondeterministic_dawg_match.rs) |
| V | [V](../../../v/b/backward_nondeterministic_dawg_match.v) |
| Zig | [Zig](../../../zig/b/backward_nondeterministic_dawg_match.zig) |
