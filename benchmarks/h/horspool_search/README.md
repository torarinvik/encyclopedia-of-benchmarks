# Horspool Search

Find the first occurrence of a pattern in a text with the case-sensitive Horspool string-search algorithm. The search compares from the pattern's right edge and advances using the bad-character shift for the text byte aligned with that edge.

## Contract

- The signed 64-bit input packs `[text_length, pattern_length, text_byte_0, ..., pattern_byte_0, ...]`.
- Text length is 0 through 512; pattern length is 0 through 64. The packed array must contain exactly `2 + text_length + pattern_length` values.
- Text and pattern bytes are ASCII values 0 through 127. ASCII keeps byte offsets aligned with Java `String`'s UTF-16 indices.
- Return the zero-based first match index. Return `-1` when the pattern is empty or no match exists. Malformed or out-of-domain input returns `-2`.
- The package uses the source's case-sensitive `findFirst` entry point. Unicode case folding from `findFirstInsensitive` is outside this contract.
- The adapter packs text before pattern for a stable array layout; it passes the pattern and text to the Java method in that method's declared order.

## Workload

[`workload.json`](workload.json) covers matches at the start and later in the text, repeated symbols, absent and longer patterns, and empty inputs.

## Reviewed source

- [Java `HorspoolSearch.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/HorspoolSearch.java) — `findFirst` builds its shift map from the pattern's second-to-last character toward the first, compares right-to-left, and returns the first match position or `-1`.

This is method-distinct from KMP and Rabin–Karp string searches: it uses a bad-character shift table and has no prefix-function or rolling-hash state.

## Implementations

The nine ports use the shared `i64_array_scalar` ABI. Their source files are in the `h` folder for each language. The source-backed oracle is implemented in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm horspool_search --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/horspool_search/rust/build.json
```
