# Acronym by space-delimited initials

Extract the first byte of each nonempty space-delimited token, uppercasing ASCII lowercase initials. The result is a byte string with no trailing NUL in the shared benchmark ABI.

## Contract

- Input is an explicit-length array of non-NUL 7-bit ASCII bytes, length 0 through 79.
- Only ASCII space (`32`) separates tokens. Repeated, leading, and trailing spaces add no initials.
- Each token contributes its first byte. Lowercase ASCII letters are mapped to uppercase; all other initial bytes are preserved. Hyphens and other punctuation are not removed or treated as word separators by this pinned C implementation.
- Return the output byte count. Invalid bytes or lengths return `-1`; insufficient output capacity returns `-2`.
- The scan takes `O(n)` time and constant auxiliary space.

## Reviewed source and normalization

The pinned C source exposes the function as `abbreviate`, copies the phrase into a fixed 80-byte buffer, splits only at literal spaces, and uppercases the first byte of each resulting token. It does not implement the broader Exercism punctuation rule, which treats hyphens as separators and allows other punctuation to be removed. Its loops also scan by a fixed counter beyond the C string terminator, so these ports preserve the intended space-token/initial-byte behavior while using an explicit-length input and a safe 79-byte maximum.

This differs from [`to_lower_case`](../../t/to_lower_case/README.md), which maps every uppercase ASCII byte to lowercase and preserves the full input length. Acronym extracts one byte per space-delimited token and uppercases only those initials.

- [TheAlgorithms/C pinned `acronym.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/acronym/acronym.c)
- [Exercism Acronym instructions](https://exercism.org/tracks/c/exercises/acronym)

## Workload and recording

`workload.json` is compact and covers empty/single-word phrases, repeated spaces, mixed-case initials, hyphens, punctuation, tabs, the 79-byte bound, and invalid input. All nine ports use the `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm acronym --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/acronym/rust/build.json
```
