"""Primary exact combinatorial oracle for DOI601's same-type contact null."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 112


def _choose(n: int, k: int) -> int:
    if k < 0 or k > n:
        return 0
    k = min(k, n - k)
    result = 1
    for i in range(1, k + 1):
        result = result * (n - k + i) // i
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) != 3 or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    length, x1, x2 = values
    if not 1 <= length <= 16 or not 0 <= x1 <= length or not 0 <= x2 <= length:
        return -1, b""

    low = max(0, x1 + x2 - length)
    high = min(x1, x2)
    denominator = _choose(length, x2)
    numerators = [_choose(x1, i) * _choose(length - x1, x2 - i) for i in range(low, high + 1)]
    expected_numerator, expected_denominator = x1 * x2, length
    divisor = math.gcd(expected_numerator, expected_denominator)
    expected_numerator //= divisor
    expected_denominator //= divisor
    words = [low, high, denominator, *numerators, expected_numerator, expected_denominator]
    payload = b"".join(struct.pack("<q", value) for value in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
