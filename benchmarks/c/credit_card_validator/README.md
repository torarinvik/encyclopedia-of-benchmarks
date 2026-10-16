# Credit card validator

The pinned Python source accepts a credit card string only when it contains decimal digits, has 13 through 16 characters, starts with one of its listed issuer prefixes, and passes its Luhn check. This benchmark covers the source's ASCII-string behavior; its diagnostic printing is excluded from the return-value ABI.

## Contract

- Uses the `i64_array_scalar` ABI. Input is `[text_length, ASCII_codepoint_0, ...]`.
- `text_length` must be 0 through 64 and the array must contain exactly `text_length + 1` values.
- Character values must be ASCII codepoints 0 through 127. Non-digit ASCII characters are well-formed strings and return `0`; out-of-range codepoints or malformed array shapes return `-1`.
- A numeric string returns `1` only if its length is 13 through 16, it starts with `34`, `35`, `37`, `4`, `5`, or `6`, and it passes Luhn validation. Other well-formed strings return `0`.
- Prefix checks intentionally follow the source's broad `startswith` rules; the package does not impose additional issuer length or number-range rules.

[`workload.json`](workload.json) covers valid prefixes, lengths, Luhn failures, nondigit ASCII, and malformed encoded inputs.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm credit_card_validator --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/credit_card_validator/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/c/credit_card_validator.c`](../../../c/c/credit_card_validator.c) |
| C3 | [`c3/c/credit_card_validator.c3`](../../../c3/c/credit_card_validator.c3) |
| C++ | [`cpp/c/credit_card_validator.cpp`](../../../cpp/c/credit_card_validator.cpp) |
| Elisa | [`elisa/c/credit_card_validator.elisa`](../../../elisa/c/credit_card_validator.elisa) |
| Nim | [`nim/c/credit_card_validator.nim`](../../../nim/c/credit_card_validator.nim) |
| Odin | [`odin/c/credit_card_validator.odin`](../../../odin/c/credit_card_validator.odin) |
| Rust | [`rust/c/credit_card_validator.rs`](../../../rust/c/credit_card_validator.rs) |
| V | [`v/c/credit_card_validator.v`](../../../v/c/credit_card_validator.v) |
| Zig | [`zig/c/credit_card_validator.zig`](../../../zig/c/credit_card_validator.zig) |

## TheAlgorithms reference

- [Python `credit_card_validator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/credit_card_validator.py)
