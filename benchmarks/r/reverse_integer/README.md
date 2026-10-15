# Reverse Integer

The pinned C LeetCode implementation pops signed decimal digits and checks the next multiply-and-add against the signed 32-bit limits. The nine portable ports preserve that algorithm and return zero when reversal overflows.

## Contract

- Input is a signed 64-bit value in the signed 32-bit range.
- Return the value with its decimal digits reversed and its sign preserved.
- Return `0` when the reversed value would be outside the signed 32-bit range.
- Return `-2,147,483,649` for inputs outside the signed 32-bit domain; this sentinel cannot be a valid result.
- The implementation uses integer division and remainder only and requires no architecture-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers zero, both signs, trailing zeroes, the signed boundaries, overflow, and invalid wide inputs. [`benchmarks/verify_reverse_integer.py`](../../verify_reverse_integer.py) compares each port against a string-based oracle over every integer from -15,000 through 15,000, seeded random signed 32-bit inputs, and boundary cases.

## Upstream source

- [TheAlgorithms/C LeetCode 7](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/7.c)
