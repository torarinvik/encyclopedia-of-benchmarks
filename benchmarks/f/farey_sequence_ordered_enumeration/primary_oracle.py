"""Constant-space successor recurrence for a bounded Farey sequence."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ORDER = 32
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_WORDS = 651
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
WORKSPACE_BYTES = 0
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _fractions(order: int) -> list[tuple[int, int]]:
    """Walk adjacent terms, beginning with 0/1 and 1/order."""
    result: list[tuple[int, int]] = [(0, 1)]
    a, b, c, d = 0, 1, 1, order
    while True:
        result.append((c, d))
        if c == d:
            return result
        k = (order + b) // d
        next_c = k * c - a
        next_d = k * d - b
        a, b, c, d = c, d, next_c, next_d


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
