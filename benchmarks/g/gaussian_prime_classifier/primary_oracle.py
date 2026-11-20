"""Primary reference: apply the norm classification with trial division."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "gaussian_prime_classifier"
INVALID_RESULT = -1
MAX_COORDINATE = 10_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_NORM = 2 * MAX_COORDINATE * MAX_COORDINATE
WORKSPACE_BYTES = 128


def _read(values: Sequence[int], input_is_null: bool,
          input_length: int) -> tuple[int, int] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length != 2:
        return None
    real, imaginary = values
    if (not -MAX_COORDINATE <= real <= MAX_COORDINATE
            or not -MAX_COORDINATE <= imaginary <= MAX_COORDINATE):
        return None
    return real, imaginary


def _trial_prime(value: int) -> bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def _classify(real: int, imaginary: int) -> int:
    if real == 0 and imaginary == 0:
        return 0
    if real == 0 or imaginary == 0:
        rational = abs(real) if real != 0 else abs(imaginary)
        return int(rational % 4 == 3 and _trial_prime(rational))
    norm = real * real + imaginary * imaginary
    return int(_trial_prime(norm))


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT
    coordinates = _read(values, input_is_null, effective_length)
    if coordinates is None:
        return INVALID_RESULT
    return _classify(*coordinates)
