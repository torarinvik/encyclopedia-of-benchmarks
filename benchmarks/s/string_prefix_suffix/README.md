# String prefix and suffix checks

Check whether an ordinal UTF-16 string begins or ends with a second string. The pinned F# sources expose separate `has_prefix` and `has_suffix` functions; this shared benchmark selects the operation with a mode field and compares their UTF-16 code units directly.

## Contract

The signed-i64 input is `[mode, text_count, pattern_count, text_code_units..., pattern_code_units...]`. Mode `0` checks a prefix and mode `1` checks a suffix. Each count is from 0 through 1,024, and each code unit is from 0 through 65,535. Return `1` when the selected check matches and `0` otherwise. A pattern longer than the text is a valid non-match. Malformed modes, lengths, counts, or code units return `-1`. Empty patterns match both prefixes and suffixes.

The shared ABI is:

```c
int64_t string_prefix_suffix(const int64_t *values, size_t length);
```

The largest valid input has 2,051 values. The runner accepts up to 2,052 values to include an extra-value malformed case.

## Workload and verification

[`workload.json`](workload.json) covers empty strings, matching and non-matching prefixes and suffixes, UTF-16 surrogate code units, the maximum counts, and malformed input. The independent oracle is [`benchmarks/string_prefix_suffix_oracle.py`](../../string_prefix_suffix_oracle.py).

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm string_prefix_suffix --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_scalar.py \
  --build-manifest build/i64_array_scalar/s/string_prefix_suffix/rust/build.json
```

Verify the registered algorithm across all nine languages with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms string_prefix_suffix
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/string_prefix_suffix.c`](../../../c/s/string_prefix_suffix.c) |
| C3 | [`c3/s/string_prefix_suffix.c3`](../../../c3/s/string_prefix_suffix.c3) |
| C++ | [`cpp/s/string_prefix_suffix.cpp`](../../../cpp/s/string_prefix_suffix.cpp) |
| Elisa | [`elisa/s/string_prefix_suffix.elisa`](../../../elisa/s/string_prefix_suffix.elisa) |
| Nim | [`nim/s/string_prefix_suffix.nim`](../../../nim/s/string_prefix_suffix.nim) |
| Odin | [`odin/s/string_prefix_suffix.odin`](../../../odin/s/string_prefix_suffix.odin) |
| Rust | [`rust/s/string_prefix_suffix.rs`](../../../rust/s/string_prefix_suffix.rs) |
| V | [`v/s/string_prefix_suffix.v`](../../../v/s/string_prefix_suffix.v) |
| Zig | [`zig/s/string_prefix_suffix.zig`](../../../zig/s/string_prefix_suffix.zig) |

## TheAlgorithms references

- [F# `HasPrefix.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/HasPrefix.fs)
- [F# `HasSuffix.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/HasSuffix.fs)
