"""Primary formula oracle for the DOI 601 heterotypic contact distribution."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 5
MAX_PARSEABLE_LENGTH = 6
MAX_OUTPUT_BYTES = 120
WORKSPACE_BYTES = 1024
MAX_SEQUENCE_LENGTH = 10


def _multinomial3(total: int, first: int, second: int) -> int:
    if total < 0 or first < 0 or second < 0 or first > total or second > total or first + second > total:
        return 0
    return math.comb(total, first) * math.comb(total - first, second)


def _histogram(length: int, x1: int, y1: int, x2: int, y2: int) -> tuple[int, list[int]]:
    denominator = _multinomial3(length, x2, y2)
    neither1 = length - x1 - y1
    numerators = [0] * (length + 1)
    for total_contacts in range(length + 1):
        for xx in range(x1 + 1):
            for xy in range(x1 - xx + 1):
                yx = total_contacts - xy
                if yx < 0 or yx > y1:
                    continue
                for yy in range(y1 - yx + 1):
                    ways = (
                        _multinomial3(x1, xx, xy)
                        * _multinomial3(y1, yx, yy)
                        * _multinomial3(neither1, x2 - xx - yx, y2 - xy - yy)
                    )
                    numerators[total_contacts] += ways
    return denominator, numerators


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_LENGTH
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) != MAX_INPUT_LENGTH or any(
        type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values
    ):
        return -1, b""
    length, x1, y1, x2, y2 = values
    if not 1 <= length <= MAX_SEQUENCE_LENGTH:
        return -1, b""
    if min(x1, y1, x2, y2) < 0 or x1 + y1 > length or x2 + y2 > length:
        return -1, b""

    denominator, numerators = _histogram(length, x1, y1, x2, y2)
    expected_numerator = sum(index * count for index, count in enumerate(numerators))
    expected_denominator = denominator
    divisor = math.gcd(expected_numerator, expected_denominator)
    expected_numerator //= divisor
    expected_denominator //= divisor
    words = [length, denominator, *numerators, expected_numerator, expected_denominator]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
