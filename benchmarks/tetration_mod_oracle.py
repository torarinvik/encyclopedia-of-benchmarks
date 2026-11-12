"""Reference oracle for bounded modular tetration."""
from __future__ import annotations

MAX_A = 1_000_000_000
MAX_B = 1_000_000_000
MAX_M = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1


def _totient(value: int) -> int:
    result = value
    remaining = value
    factor = 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            result -= result // factor
            while remaining % factor == 0:
                remaining //= factor
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        result -= result // remaining
    return result


def _power_capped(base: int, exponent: int, cap: int) -> int:
    result = 1
    factor = min(base, cap)
    while exponent > 0:
        if exponent & 1:
            result *= factor
            if result >= cap:
                return cap
        exponent >>= 1
        if exponent:
            factor *= factor
            if factor >= cap:
                factor = cap
    return min(result, cap)


def _tower_capped(base: int, height: int, cap: int) -> int:
    if height == 0:
        return min(1, cap)
    if base == 0:
        return int(height % 2 == 0)
    if base == 1:
        return min(1, cap)
    value = 1
    if value >= cap:
        return cap
    for _ in range(height):
        value = _power_capped(base, value, cap)
        if value >= cap:
            return cap
    return value


def _tetration_mod(base: int, height: int, modulus: int) -> int:
    if modulus == 1:
        return 0
    if height == 0:
        return 1 % modulus
    if height == 1:
        return base % modulus
    exponent_modulus = _totient(modulus)
    exponent = _tetration_mod(base, height - 1, exponent_modulus)
    if _tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus:
        exponent += exponent_modulus
    return pow(base, exponent, modulus)


def expected_result(
    values: list[int] | tuple[int, ...] | None,
    algorithm: str = "tetration_mod",
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    if (algorithm != "tetration_mod" or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int
                     or input_length != len(values)
                     or input_length > MAX_PARSEABLE_INPUT_LENGTH))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    base, height, modulus = values
    if not (0 <= base <= MAX_A and 0 <= height <= MAX_B and 1 <= modulus <= MAX_M):
        return INVALID_RESULT
    return _tetration_mod(base, height, modulus)
