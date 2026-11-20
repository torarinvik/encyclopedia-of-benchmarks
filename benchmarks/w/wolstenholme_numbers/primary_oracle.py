"""Reduced-rational recurrence for Wolstenholme numbers A007406."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 22
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_LCM = 54_192_375_991_353_600
MAX_INTERMEDIATE_NUMERATOR = 2 * MAX_LCM
MAX_RESULT = 86_364_397_717_734_821
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _gcd(a: int, b: int) -> int:
    while b:
        a, b = b, a % b
    return a


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _numerator(n: int) -> int:
    numerator = 0
    denominator = 1
    for k in range(1, n + 1):
        square = k * k
        common = _gcd(denominator, square)
        scale = square // common
        numerator = numerator * scale + denominator // common
        denominator *= scale
        reduce_by = _gcd(numerator, denominator)
        numerator //= reduce_by
        denominator //= reduce_by
    return numerator


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the reduced numerator of H_n^(2), or -1 for invalid framing."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _numerator(n)

