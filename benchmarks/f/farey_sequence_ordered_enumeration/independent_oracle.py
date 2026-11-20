"""GCD enumeration and exact rational sorting, independent of the successor walk."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from functools import cmp_to_key

MAX_ORDER = 32
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_WORDS = 651
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
WORKSPACE_BYTES = 0
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _fractions(order: int) -> list[tuple[int, int]]:
    fractions = [
        (numerator, denominator)
        for denominator in range(1, order + 1)
        for numerator in range(denominator + 1)
        if math.gcd(numerator, denominator) == 1
    ]

    def compare(left: tuple[int, int], right: tuple[int, int]) -> int:
        difference = left[0] * right[1] - right[0] * left[1]
        return (difference > 0) - (difference < 0)

    return sorted(fractions, key=cmp_to_key(compare))


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null and values is not None and input_length is not None
        and input_length != len(values)
    ):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) != 1 or not 1 <= values[0] <= MAX_ORDER:
        return -1, b""

    fractions = _fractions(values[0])
    words = [len(fractions)]
    for numerator, denominator in fractions:
        words.extend((numerator, denominator))
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
