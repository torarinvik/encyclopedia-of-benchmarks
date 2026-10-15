# Check vowels

Returns whether a string contains at least one of the five lowercase ASCII vowels: `a`, `e`, `i`, `o`, or `u`.

## Contract

- Uses the `i64_array_scalar` ABI with an array of lowercase ASCII letter code values.
- Accepts arrays of length 0 through 4,096; every code value must be in 97..122 (`a`..`z`). Invalid lengths or values return `-1`.
- Returns `1` when at least one vowel is present and `0` otherwise. The empty string returns `0`.

## Source semantics

This follows pinned [TheAlgorithms Java `CheckVowels.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/CheckVowels.java). Its `hasVowels` method returns false for null or empty input, lowercases the string, and returns true on the first `a`, `e`, `i`, `o`, or `u`. The benchmark uses lowercase ASCII input, where lowercasing is an identity operation. This restriction avoids Java's default-locale behavior for uppercase `I` and differences in Unicode case mapping. Null is not represented by the array ABI; the empty string is represented by an empty array.

The existing `count_vowels` benchmark counts vowel occurrences, while this operation returns only whether any vowel occurs.

## Workload and build

[`workload.json`](workload.json) covers empty, vowel-containing, and consonant-only strings, along with an invalid uppercase code value. Build and record with the array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm check_vowels --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/check_vowels/rust/build.json
```

The nine implementations are in `c/c/check_vowels.c`, `c3/c/check_vowels.c3`, `cpp/c/check_vowels.cpp`, `elisa/c/check_vowels.elisa`, `nim/c/check_vowels.nim`, `odin/c/check_vowels.odin`, `rust/c/check_vowels.rs`, `v/c/check_vowels.v`, and `zig/c/check_vowels.zig`.
