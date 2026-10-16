"""Normalize the pinned proper-fractions list as newline-delimited ASCII."""

from __future__ import annotations

MAX_INPUT_LENGTH = 2


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 1
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    denominator = values[0]
    if not 0 <= denominator <= 256:
        return -1, b""
    output = b"".join(f"{numerator}/{denominator}\n".encode("ascii")
                      for numerator in range(1, denominator)
                      if _gcd(numerator, denominator) == 1)
    return len(output), output
