"""String-digit and congruence reference for the Dividuus predicate."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 100_000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_DIGIT_SUM = 45
MAX_DIGIT_PRODUCT = 59_049
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


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
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _digit_values(value: int) -> list[int]:
    return [ord(character) - ord("0") for character in str(value)]


def _multiplicative_root_from_text(value: int) -> int:
    while value >= 10:
        value = math.prod(_digit_values(value))
    return value


def _is_dividuus(n: int) -> int:
    digits = _digit_values(n)
    digit_sum = sum(digits)
    digit_product = math.prod(digits)
    digital_root = 1 + (n - 1) % 9
    multiplicative_root = _multiplicative_root_from_text(digit_product)
    divisors = (digit_sum, digit_product, digital_root, multiplicative_root)
    if any(divisor == 0 for divisor in divisors):
        return 0
    return int(all(n % divisor == 0 for divisor in divisors))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Use decimal digit vectors and the modulo-nine digital-root identity."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _is_dividuus(n)
