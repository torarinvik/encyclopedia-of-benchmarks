"""Independent oracle for bounded Fermat modular inverse."""

from __future__ import annotations

MAX_MODULUS = 1_000_000
MAX_ABSOLUTE_BASE = 1_000_000
MAX_INPUT_LENGTH = 3
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    base, modulus = values
    if (not -MAX_ABSOLUTE_BASE <= base <= MAX_ABSOLUTE_BASE
            or not 2 <= modulus <= MAX_MODULUS
            or base == 0 or not -modulus < base < modulus
            or not _is_prime(modulus)):
        return INVALID_RESULT
    return pow(base % modulus, modulus - 2, modulus)
