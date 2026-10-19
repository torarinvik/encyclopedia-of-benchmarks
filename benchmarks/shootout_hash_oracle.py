"""Independent oracle for the bounded Shootout hash benchmark profile."""

from __future__ import annotations

MAX_N = 3_500_000
REFERENCE_RESULT = 356_799


def _decimal_keys_hit_by_hex_table(n: int) -> int:
    """Count i in 1..n whose decimal spelling is an inserted hexadecimal key.

    A decimal lookup string hits exactly when interpreting the same digits as
    base 16 produces a table key no greater than n. Count those digit strings
    directly in base 16 instead of building the source hash table.
    """
    if n <= 0:
        return 0

    reversed_hex_digits: list[int] = []
    remaining = n
    while remaining:
        reversed_hex_digits.append(remaining & 0xF)
        remaining >>= 4
    limit_digits = list(reversed(reversed_hex_digits))

    total = sum(9 * 10 ** (length - 1) for length in range(1, len(limit_digits)))
    for position, limit_digit in enumerate(limit_digits):
        minimum_digit = 1 if position == 0 else 0
        choices_below = max(0, min(9, limit_digit - 1) - minimum_digit + 1)
        total += choices_below * 10 ** (len(limit_digits) - position - 1)
        if limit_digit < minimum_digit or limit_digit > 9:
            break
        if position + 1 == len(limit_digits):
            total += 1
    return total


def expected_result(n: int) -> int:
    """Return the bounded number of successful decimal lookups, or -1."""
    if type(n) is not int or not 0 <= n <= MAX_N:
        return -1
    return _decimal_keys_hit_by_hex_table(n)
