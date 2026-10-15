# Digital Root

The digital root is found by repeatedly summing the decimal digits until one digit remains. For example, `284 -> 14 -> 5`. The shared benchmark follows this repeated-sum algorithm so the nine language ports perform the same operation.

## Contract

- Input is a signed 64-bit integer.
- Inputs from `0` through `9,223,372,036,854,775,807` are valid. Negative values return `-1`.
- A valid input returns its digital root, in the range `0` through `9`.
- Zero returns zero; a positive multiple of nine returns nine.
- Each implementation uses portable integer division and remainder. No architecture-specific instructions or floating point are used.

## Workload and verification

[`workload.json`](workload.json) covers zero, one-digit values, repeated reductions, powers of ten, large signed-64-bit boundaries, and invalid negative inputs. [`verify_scalar.py`](../../verify_scalar.py) checks the nine implementations against an independent repeated-sum oracle over every value from `-16` through `10,000`, 512 deterministic signed-64-bit samples, and explicit boundaries. It also verifies the benchmark recorder output for every workload case.

## Reviewed TheAlgorithms sources

- [Java `DigitalRoot.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/DigitalRoot.java) — recursively sums decimal digits, then repeats until a single digit remains.
- [Python `digital_root.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/digital_root.py) — iteratively sums digits until a single digit remains.
- [Ruby `add_digits.rb` (recursive)](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/add_digits.rb) — recursively repeats the digit sum; this source candidate aliases the `digital_root` contract.
- [Ruby `add_digits.rb` (modulo 9)](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/add_digits.rb) — computes the same result with the constant-time digital-root formula.

The local contract narrows inputs to nonnegative signed-64-bit integers, matching the stated input domain of the Add Digits sources and keeping invalid-input behavior explicit. The Ruby modulo-9 source is recorded as the mathematical variant; the benchmark ports use repeated summation for a consistent algorithmic comparison.
