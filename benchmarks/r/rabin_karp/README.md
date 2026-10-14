# Rabin–Karp search

This benchmark uses a polynomial rolling hash to determine whether a pattern occurs in a text. Hash matches are confirmed by comparing the corresponding bytes, so collisions cannot produce a false positive.

## Contract

- The input packs two sequences as `[text_length, pattern_length, text_ascii_values..., pattern_ascii_values...]`.
- Each sequence length is from 0 through 255, each value is from 0 through 127, and the packed array must contain exactly `2 + text_length + pattern_length` values.
- The function returns `1` when the pattern occurs and `0` when it does not. An empty pattern is defined as present, including in an empty text. Invalid packed input returns `-1`.
- The implementation uses a base-256 rolling hash modulo 1,000,003 and verifies equal-hash windows byte by byte. It uses portable integer operations and allocates no memory.

The pinned TheAlgorithms sources agree on Rabin–Karp pattern search, but expose different results: the C++ sources return the first index, several implementations return all indices, and Python and F# return a boolean. The shared contract normalizes these to pattern presence. Some upstream sources leave empty-pattern behavior unspecified or differ, so this contract explicitly treats an empty pattern as present. The ASCII restriction makes byte-based and character-indexed sources use the same offsets.

## Inspected upstream sources

- [C-Plus-Plus — `strings/rabin_karp.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/rabin_karp.cpp)
- [C-Plus-Plus-1 — `strings/rabin_karp.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/rabin_karp.cpp)
- [C-Sharp — `Algorithms/Strings/PatternMatching/RabinKarp.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/PatternMatching/RabinKarp.cs)
- [F-Sharp — `Algorithms/Strings/RabinKarp.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/RabinKarp.fs)
- [Java — `src/main/java/com/thealgorithms/strings/RabinKarp.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/RabinKarp.java)
- [JavaScript — `Search/RabinKarp.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/RabinKarp.js)
- [Julia — `src/strings/rabin_karp.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/rabin_karp.jl)
- [Python — `strings/rabin_karp.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/rabin_karp.py)
- [Rust — `src/string/rabin_karp.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/rabin_karp.rs)

## Workload and verification

`workload.json` covers empty inputs, matches at different positions, misses, overlapping and repeated matches, ASCII boundaries, a crafted hash collision, maximum lengths, and invalid packed data. The verifier compares against a naive substring oracle, exhausts all pairs of binary-alphabet sequences through length five, and adds deterministic random pairs and boundary cases in all nine languages.

```sh
python3 benchmarks/verify_rabin_karp.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Sources are under `r/` in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`.
