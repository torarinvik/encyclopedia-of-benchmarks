# Roman Numeral to Integer

Decode a canonical uppercase Roman numeral using the standard place-value groups for thousands, hundreds, tens, and ones. Each group accepts only its canonical subtractive and repetition patterns.

## Contract

- Input is an array of signed 64-bit integers representing ASCII code points, with length 1 through 15.
- Valid symbols are uppercase `I`, `V`, `X`, `L`, `C`, `D`, and `M`.
- Return the represented value from 1 through 3,999. Empty input, invalid symbols, noncanonical forms, and out-of-range values return -1.

## Workload and verification

[`workload.json`](workload.json) covers standard subtractive pairs, range boundaries, malformed repetitions, unknown symbols, and lowercase input. [`benchmarks/verify_roman_to_integer.py`](../../verify_roman_to_integer.py) checks all nine ports against a canonical-form oracle, including all 3,999 valid numerals, exhaustive short symbol sequences, boundaries, and seeded random inputs.

## Reviewed TheAlgorithms sources

The pinned C [`roman_numerals_to_decimal`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/roman_numerals_to_decimal.c), JavaScript [`RomanToDecimal`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RomanToDecimal.js), Dart and Java [`roman_to_integer`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/RomanToInteger.java), Ruby [`roman_to_integer`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/roman_to_integer.rb), Go [`romantoint`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/conversion/romantoint.go), and Python/Rust [`roman_numerals`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/roman_numerals.py) files implement the inverse conversion with differing case and validation behavior. The benchmark standardizes to canonical uppercase input and rejects malformed forms.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
