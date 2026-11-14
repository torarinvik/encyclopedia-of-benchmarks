# Shortest absent substring via suffix automaton (in progress)

Given a bounded sequence over an ordered alphabet, return the lexicographically
smallest shortest nonempty sequence that is not a contiguous substring. Build
a suffix automaton for the input, then compute the shortest path from each
state to a missing alphabet transition. Follow minimum-length transitions in
ascending symbol order to reconstruct the answer.

The `i64_array_bytes_output` input is `[alphabet_size,n,symbols...]` with
`2<=alphabet_size<=4`, `0<=n<=64`, each symbol in `0..alphabet_size-1`, and
exact length `2+n`. Output the answer as raw symbol bytes. A shortest absent
substring has length at most six: there are 64 binary words of length six,
more than the at most 59 length-six windows in any input of length 64.
Invalid input returns `-1`; a null or insufficient output buffer returns `-2`
without writes. Maximum input length is 66 i64 words and maximum output is six
bytes. The suffix automaton has at most `2*n+1` states. With a fixed alphabet,
construction, length-ordered DP and reconstruction take O(n+alphabet_size)
time and O(n*alphabet_size) space; n=0 uses the initial state alone.

This differs from [`suffix_automaton`](../suffix_automaton/README.md), which
answers membership, occurrence and distinct-substring queries but has no
shortest-absent output. Source: [CP-Algorithms, suffix automaton applications](https://cp-algorithms.com/string/suffix-automaton.html).
The page is CC BY-SA 4.0; only the mathematical idea is used. No page code,
prose, examples or tests are copied.

**Status:** contract, workload, two references, ten language drafts and
byte-output suite registration are present. No code has been executed;
validation remains.
The suite source specifies an order-five binary de Bruijn fixture reaching the
six-byte output bound, exhaustive small inputs and malformed-input precedence.

| Language | Draft |
| --- | --- |
| C | [`c/s/shortest_absent_substring_sam.c`](../../../c/s/shortest_absent_substring_sam.c) |
| C3 | [`c3/s/shortest_absent_substring_sam.c3`](../../../c3/s/shortest_absent_substring_sam.c3) |
| C++ | [`cpp/s/shortest_absent_substring_sam.cpp`](../../../cpp/s/shortest_absent_substring_sam.cpp) |
| Elisa | [`elisa/s/shortest_absent_substring_sam.elisa`](../../../elisa/s/shortest_absent_substring_sam.elisa) |
| Mojo | [`mojo/s/shortest_absent_substring_sam.mojo`](../../../mojo/s/shortest_absent_substring_sam.mojo) |
| Nim | [`nim/s/shortest_absent_substring_sam.nim`](../../../nim/s/shortest_absent_substring_sam.nim) |
| Odin | [`odin/s/shortest_absent_substring_sam.odin`](../../../odin/s/shortest_absent_substring_sam.odin) |
| Rust | [`rust/s/shortest_absent_substring_sam.rs`](../../../rust/s/shortest_absent_substring_sam.rs) |
| V | [`v/s/shortest_absent_substring_sam.v`](../../../v/s/shortest_absent_substring_sam.v) |
| Zig | [`zig/s/shortest_absent_substring_sam.zig`](../../../zig/s/shortest_absent_substring_sam.zig) |
