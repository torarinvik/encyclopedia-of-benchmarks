# Any base to any base

This benchmark converts a digit sequence from one radix to another. It follows the pinned Java source's two-stage method: fold the source digits into a checked decimal value, then repeatedly divide by the target radix.

## Contract

- Input is `[source_base, target_base, digit...]`, with one or more most-significant-first digits. The array length is 3 through 65.
- Both radices are 2 through 36. Digits use values 0 through 35 for `0`-`9` and `A`-`Z`; each must be less than the source radix.
- The source value must fit a nonnegative signed 64-bit integer. Invalid digits, radices, lengths, or overflow return `-1`; insufficient output capacity returns `-2`.
- Output is canonical uppercase ASCII with no sign or prefix. The return value is the exact number of output bytes; the buffer is not NUL-terminated. Implementations use portable checked multiply-and-add and integer division.

## Workload and verification

[`workload.json`](workload.json) covers common radix pairs, leading zeroes, signed 64-bit limits, invalid digits and radices, overflow, and excessive length. [`verify_decimal_to_any_base.py`](../../verify_decimal_to_any_base.py) accepts `--algorithm any_base_to_any_base` and checks short digit sequences, deterministic random values, and the workload against Python's arbitrary-precision oracle.

## Reviewed TheAlgorithms source

- [Java `AnyBaseToAnyBase.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/AnyBaseToAnyBase.java) supports radices 2 through 36 and validates uppercase digits. The pinned implementation folds into a signed 32-bit accumulator; this benchmark makes overflow explicit for a shared signed 64-bit contract.
- JavaScript's [`ArbitraryBase.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/ArbitraryBase.js) supports custom character alphabets and includes an exact `BigInt` variant. Under the standard `0`-`9`, `A`-`Z` alphabet, it is cataloged as an alias of this base-conversion benchmark.
