# Number of digits

This algorithm counts the base-10 digits of an integer. The inspected upstream code offers arithmetic, logarithmic, and string-based variants. Their input behavior differs: TypeScript accepts only positive values, while the Ruby division loop does not terminate for a negative value.

## Contract

The input is any signed 64-bit integer. The result is the number of decimal digits in its magnitude; zero has one digit. The sign is not counted. The implementation handles the signed 64-bit minimum without taking its unrepresentable positive absolute value, then repeatedly divides the unsigned magnitude by ten.

## Reproduce

```sh
python3 benchmarks/build_scalar.py --algorithm number_of_digits --language c
python3 benchmarks/run_scalar.py --algorithm number_of_digits
python3 benchmarks/verify_scalar.py --algorithms number_of_digits --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The scalar verifier checks dense small values, random signed 64-bit inputs, every decimal power and neighboring values through 10^18, and both signed boundaries.

Upstream references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/NumberOfDigits.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/NumberOfDigits.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/number_of_digits.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/number_of_digits.rb), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/number_of_digits.ts).
