# Indian phone number validator

## Contract

This benchmark follows the pinned Python `indian_phone_validator` regular
expression:

```text
^(\+91[\-\s]?)?[0]?(91)?[789]\d{9}$
```

It accepts byte arrays containing 1 through 18 ASCII characters. Each array
element is one signed 64-bit slot holding the ASCII value of a character. A
matching input returns `1`; other in-domain ASCII strings return `0`. Empty,
oversized, or non-ASCII input returns `-1`.

The source uses `re.search` with `^` and `$`. Python's `$` anchor also matches
immediately before one final line feed, so that final `\n` is included in the
accepted behavior. The longest pattern body is 17 characters; the optional
single final line feed makes the input bound 18. In the optional separator,
ASCII `\s` means space, tab, line feed, carriage return, form feed, or vertical
tab; the other allowed separator is a hyphen. Python's Unicode `\d` extension
is outside this ASCII benchmark domain.

The shared `i64_array_scalar` ABI represents the source string as bytes. The
validator is distinct from [`is_srilankan_phone_number`](../is_srilankan_phone_number/README.md),
which uses Sri Lankan prefixes and area digits.

## Workload and build

[`workload.json`](workload.json) covers international and local forms, each
optional prefix, supported separators, the final-line-feed behavior, and
malformed inputs.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm indian_phone_validator --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/indian_phone_validator/c/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/i/indian_phone_validator.c`](../../../c/i/indian_phone_validator.c) |
| C3 | [`c3/i/indian_phone_validator.c3`](../../../c3/i/indian_phone_validator.c3) |
| C++ | [`cpp/i/indian_phone_validator.cpp`](../../../cpp/i/indian_phone_validator.cpp) |
| Elisa | [`elisa/i/indian_phone_validator.elisa`](../../../elisa/i/indian_phone_validator.elisa) |
| Nim | [`nim/i/indian_phone_validator.nim`](../../../nim/i/indian_phone_validator.nim) |
| Odin | [`odin/i/indian_phone_validator.odin`](../../../odin/i/indian_phone_validator.odin) |
| Rust | [`rust/i/indian_phone_validator.rs`](../../../rust/i/indian_phone_validator.rs) |
| V | [`v/i/indian_phone_validator.v`](../../../v/i/indian_phone_validator.v) |
| Zig | [`zig/i/indian_phone_validator.zig`](../../../zig/i/indian_phone_validator.zig) |

## Pinned source

- Python [`indian_phone_validator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/indian_phone_validator.py)
