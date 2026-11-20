"""Trial-division reference for the bounded Chernick multiplier search."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_N = 3
MAX_N = 9
MAX_MULTIPLIER = 950_560
MAX_FACTOR = (9 * MAX_MULTIPLIER << (MAX_N - 2)) + 1
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 4096


def _is_prime(value: int) -> bool:
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


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not MIN_N <= values[0] <= MAX_N:
        return None
    return values[0]


def _step(n: int) -> int:
    step = 1 << max(0, n - 4)
    if n > 5:
        step *= 5
    return step


def _factors(n: int, multiplier: int) -> tuple[int, ...]:
    factors = [6 * multiplier + 1, 12 * multiplier + 1]
    for exponent in range(1, n - 1):
        factors.append((9 * multiplier << exponent) + 1)
    return tuple(factors)


def least_multiplier(n: int) -> int:
    step = _step(n)
    for multiplier in range(step, MAX_MULTIPLIER + 1, step):
        if all(_is_prime(factor) for factor in _factors(n, multiplier)):
            return multiplier
    return -1


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _decode(values, input_is_null, input_length)
    if n is None:
        return -1
    return least_multiplier(n)
