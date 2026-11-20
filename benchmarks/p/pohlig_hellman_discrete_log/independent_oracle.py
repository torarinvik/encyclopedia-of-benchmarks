"""Direct-power enumeration oracle for small finite-field discrete logs."""

from __future__ import annotations

from collections.abc import Sequence

MIN_P = 3
MAX_P = 1_009
MAX_PARSEABLE_INPUT_LENGTH = 4


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, int] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 3:
        return None
    p, base, target = values
    if p < MIN_P or p > MAX_P or base < 1 or base >= p or target < 0 or target >= p:
        return None
    return p, base, target


def _trial_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _direct_log(base: int, target: int, modulus: int) -> int:
    residue = 1
    for exponent in range(modulus - 1):
        if residue == target:
            return exponent
        residue = residue * base % modulus
    return -2


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    modulus, base, target = decoded
    if not _trial_prime(modulus):
        return -1
    return _direct_log(base, target, modulus)


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return type(result) is int and result == expected_result(values, input_is_null, input_length)
