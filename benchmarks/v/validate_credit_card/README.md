# Validate credit card (JavaScript parity)

This benchmark preserves the pinned JavaScript validator's Luhn loop, including its left-to-right parity: it doubles digits at even zero-based positions, independent of the string length. For even-length numbers this matches the conventional right-to-left Luhn parity; for odd lengths it can disagree with standard validators. The return-value benchmark projects the source's `true`/throw outcomes to `1`/`0` for a bounded ASCII input ABI.

## Contract

- Input is `[text_length, ASCII_codepoint...]`, with 0..64 bytes and exact array length `text_length + 1`.
- Non-ASCII codepoints and malformed array shapes return `-1`. Well-formed ASCII strings return `1` only when every character is a decimal digit, the length is 13..16, the prefix is `4`, `5`, `6`, `34`, `35`, or `37`, and the source's left-index-even Luhn sum is divisible by 10. Other ASCII strings return `0`.
- The measured operation uses the same validation stages and index parity as the pinned JavaScript source. Diagnostic exceptions and messages are outside the scalar ABI.

The 13-digit cases `4222222222222` and `4222222222220` distinguish this source's parity from the conventional length-aware Luhn implementation.

Build and verify with the shared array-scalar tools:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms validate_credit_card --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Source

The pinned [JavaScript `ValidateCreditCard.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/ValidateCreditCard.js) checks numeric conversion, length, issuer prefix, then doubles digits at even zero-based indices from the left. It returns `true` on success and throws otherwise; this benchmark maps success to 1 and validation failures to 0.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/v/validate_credit_card.c`](../../../c/v/validate_credit_card.c) |
| C3 | [`c3/v/validate_credit_card.c3`](../../../c3/v/validate_credit_card.c3) |
| C++ | [`cpp/v/validate_credit_card.cpp`](../../../cpp/v/validate_credit_card.cpp) |
| Elisa | [`elisa/v/validate_credit_card.elisa`](../../../elisa/v/validate_credit_card.elisa) |
| Nim | [`nim/v/validate_credit_card.nim`](../../../nim/v/validate_credit_card.nim) |
| Odin | [`odin/v/validate_credit_card.odin`](../../../odin/v/validate_credit_card.odin) |
| Rust | [`rust/v/validate_credit_card.rs`](../../../rust/v/validate_credit_card.rs) |
| V | [`v/v/validate_credit_card.v`](../../../v/v/validate_credit_card.v) |
| Zig | [`zig/v/validate_credit_card.zig`](../../../zig/v/validate_credit_card.zig) |
