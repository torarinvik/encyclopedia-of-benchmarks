"""LCM-scaled exact-sum reference for Wolstenholme numbers."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 22
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_LCM = 54_192_375_991_353_600
MAX_RESULT = 86_364_397_717_734_821
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _gcd(x: int, y: int) -> int:
    while y != 0:
        x, y = y, x % y
    return x


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values) or size != 1:
        return None
    return values[0] if 1 <= values[0] <= MAX_N else None


def _lcm(a: int, b: int) -> int:
    return (a // _gcd(a, b)) * b


def _numerator(n: int) -> int:
    common_denominator = 1
    for k in range(1, n + 1):
        common_denominator = _lcm(common_denominator, k * k)
    scaled_sum = 0
    for k in range(1, n + 1):
        scaled_sum += common_denominator // (k * k)
    return scaled_sum // _gcd(scaled_sum, common_denominator)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Build an LCM-scaled sum, reduce once, and return its numerator."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _numerator(n)

