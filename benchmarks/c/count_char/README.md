# Count non-whitespace characters

## Contract

This benchmark follows the pinned Java `CountChar.countCharacters` method from [TheAlgorithms/Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/CountChar.java).

The packed input is an array of ASCII code values in `0..127`, with length `0..4096`. Return the number of codes other than Java default-regex whitespace `{9, 10, 11, 12, 13, 32}`. Empty input returns 0. Values outside the code or length bounds return -1. The array is not modified.

The source returns 0 for a null string, but this array ABI has no separate null-string representation. Empty input is the portable zero-length equivalent. The operation counts non-whitespace code units; it does not count letters or words. Restricting to ASCII makes Java's UTF-16 `String.length()` and the numeric code array agree exactly.

Each implementation exports the existing `i64_array_scalar` ABI:

```c
int64_t count_char(const int64_t *values, size_t length);
```

## Workload

`workload.json` includes empty input, each excluded whitespace code, repeated non-whitespace characters, embedded NUL, and malformed code and length cases.

## Implementations

The nine ports are in the matching `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/` directories.
