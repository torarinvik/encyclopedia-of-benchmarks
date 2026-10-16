# Wildcard matching

Match a lowercase ASCII text against a full-string wildcard pattern. `?` matches one character and `*` matches any sequence, including an empty sequence.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the `i64_array_scalar` ABI.
- Text length is 0–12; pattern length is 0–20. Text contains lowercase ASCII letters. Patterns contain lowercase ASCII letters, `?`, and `*`; consecutive and leading stars are allowed.
- Return `1` for a full match and `0` for a valid non-match. Invalid packed lengths, bounds, or characters return `-1`.
- The selected source methods use dynamic programming or memoized recursion for the same `?`/`*` recurrence. Each port uses a fresh bounded DP table per call; the input limits keep the table small and recursion shallow.

The C++ sources keep a process-global memo table without clearing it between calls, which can reuse stale answers. The benchmark gives every call an isolated table and follows the shared wildcard semantics. The Java `RegexMatching` class includes both direct recursion and tabulation; the tabulation recurrence supplies its bounded contract. Python's separate `wildcard_pattern_matching` uses `.` and preceding-atom `*`, so it maps to the existing [`regex_match`](../../r/regex_match/README.md) contract instead.

[`workload.json`](workload.json) covers empty and nonempty strings, literal and question-mark matches, leading and consecutive stars, full-string rejection, maximum lengths, and malformed input. The independent dynamic-programming oracle is [`wildcard_matching_oracle.py`](../../wildcard_matching_oracle.py).

## Pinned sources

- [C-Plus-Plus `wildcard_matching.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/wildcard_matching.cpp)
- [C-Plus-Plus-1 `wildcard_matching.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/backtracking/wildcard_matching.cpp)
- [Java `WildcardMatching.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/WildcardMatching.java)
- [Java `RegexMatching.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/RegexMatching.java)
- [Python `wildcard_matching.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/wildcard_matching.py)
- [Go `wildcardmatching.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/wildcardmatching.go)

## Build and verify

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm wildcard_matching --language rust
    python3 benchmarks/verify_i64_array_scalar.py --algorithms wildcard_matching

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wildcard_matching.c`](../../../c/w/wildcard_matching.c) |
| C3 | [`c3/w/wildcard_matching.c3`](../../../c3/w/wildcard_matching.c3) |
| C++ | [`cpp/w/wildcard_matching.cpp`](../../../cpp/w/wildcard_matching.cpp) |
| Elisa | [`elisa/w/wildcard_matching.elisa`](../../../elisa/w/wildcard_matching.elisa) |
| Nim | [`nim/w/wildcard_matching.nim`](../../../nim/w/wildcard_matching.nim) |
| Odin | [`odin/w/wildcard_matching.odin`](../../../odin/w/wildcard_matching.odin) |
| Rust | [`rust/w/wildcard_matching.rs`](../../../rust/w/wildcard_matching.rs) |
| V | [`v/w/wildcard_matching.v`](../../../v/w/wildcard_matching.v) |
| Zig | [`zig/w/wildcard_matching.zig`](../../../zig/w/wildcard_matching.zig) |
