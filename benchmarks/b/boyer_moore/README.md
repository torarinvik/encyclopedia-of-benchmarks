# Boyer–Moore

## Contract

Given packed ASCII byte sequences `[text_length, pattern_length, text_bytes..., pattern_bytes...]`, return the byte offset of the first match. Text and pattern lengths are each limited to 4,096 bytes, and values must be in `[0, 126]`. An empty pattern matches at offset `0`; an absent pattern or malformed input returns `-1`.

The search compares bytes from right to left and advances by the larger of the bad-character and strong good-suffix shifts. It uses the existing `i64_array_scalar` ABI.

## Relation to Boyer–Moore Search

[`boyer_moore_search`](../boyer_moore_search/README.md) uses the bad-character rule alone. This benchmark covers full Boyer–Moore's combined bad-character and good-suffix shifts, so it measures a distinct search algorithm even though both return the first matching offset. The C++ source returns all match positions; this contract standardizes the first position to align with the C# and Java string-search APIs. The C++ source does not handle an empty pattern before subtracting one from its length, so this contract defines the empty-pattern result explicitly.

## Workload and recording

[`workload.json`](workload.json) covers empty inputs, first and later matches, overlaps, control bytes, the highest accepted ASCII byte, and a case whose matched suffix enables a larger good-suffix shift. Runtime verification remains pending.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm boyer_moore --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm boyer_moore
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/boyer_moore.c`](../../../c/b/boyer_moore.c) |
| C3 | [`c3/b/boyer_moore.c3`](../../../c3/b/boyer_moore.c3) |
| C++ | [`cpp/b/boyer_moore.cpp`](../../../cpp/b/boyer_moore.cpp) |
| Elisa | [`elisa/b/boyer_moore.elisa`](../../../elisa/b/boyer_moore.elisa) |
| Nim | [`nim/b/boyer_moore.nim`](../../../nim/b/boyer_moore.nim) |
| Odin | [`odin/b/boyer_moore.odin`](../../../odin/b/boyer_moore.odin) |
| Rust | [`rust/b/boyer_moore.rs`](../../../rust/b/boyer_moore.rs) |
| V | [`v/b/boyer_moore.v`](../../../v/b/boyer_moore.v) |
| Zig | [`zig/b/boyer_moore.zig`](../../../zig/b/boyer_moore.zig) |

## TheAlgorithms references

- C++ [`strings/boyer_moore.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/boyer_moore.cpp) uses both shift tables and returns all matches.
- C# [`Algorithms/Strings/PatternMatching/BoyerMoore.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/PatternMatching/BoyerMoore.cs) uses both shifts and returns the first match.
- Java [`searches/BoyerMoore.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/BoyerMoore.java) and JavaScript [`String/BoyerMoore.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/BoyerMoore.js) use bad-character-style shifts without the good-suffix table.
