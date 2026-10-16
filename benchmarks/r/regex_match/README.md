# Regular expression matching

Match a lowercase ASCII text string against the supported regular-expression subset using direct recursive backtracking. A period matches any single character. An asterisk matches zero or more occurrences of the immediately preceding atom. Matching must cover the whole text.

## Contract

- Input is a signed 64-bit array `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
- Text length is 0 through 12; pattern length is 0 through 20.
- Text contains lowercase ASCII letters. Patterns contain lowercase ASCII letters, `.`, and `*`; every `*` must follow one atom, and adjacent `*` characters are invalid.
- Return `1` for a full match and `0` for a valid non-match. Invalid arrays or patterns return `-1`.
- The implementation uses the direct recursive include-zero-or-more recurrence without memoization. The input limits bound worst-case backtracking while preserving the source algorithm.

## Workload and verification

[`workload.json`](workload.json) includes empty strings, literal and dot matches, zero and repeated star matches, multiple starred atoms, full-string rejection, invalid patterns, and a bounded worst-case non-match. [`verify_regex_match.py`](../../verify_regex_match.py) compares all nine implementations with an independent dynamic-programming oracle, exhausts short binary texts and valid patterns, and adds deterministic random, malformed, and boundary inputs.

```sh
python3 benchmarks/verify_regex_match.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Sources are under `r/` in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`.

## Reviewed TheAlgorithms sources

- [C LeetCode `10.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/10.c) applies direct recursive full-string matching for `.` and `*`.
- [Python `regex_match.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/regex_match.py) includes both recursive and dynamic-programming versions of the same `.` and preceding-atom `*` matching rule. This benchmark selects the recursive version.
- [C# `WildCardMatcher.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/PatternMatching/WildCardMatcher.cs) uses bottom-up dynamic programming for the same grammar; it rejects a leading `*`, which is already invalid under this contract.

Java `RegexMatching.java` uses `?` for one character and `*` for any sequence, so it maps to the separate [wildcard_matching](../../w/wildcard_matching/README.md) contract. Python `wildcard_pattern_matching.py` uses `.` and preceding-atom `*`, so it aliases this regular-expression contract.
