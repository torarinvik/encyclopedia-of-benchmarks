"""Independent position-map verifier for the Transpose list-update trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_REQUESTS = 32
MAX_INPUT_LENGTH = 42


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63) for item in values):
        return None
    count = values[0]
    request_count = values[1]
    if not 1 <= count <= MAX_N or not 0 <= request_count <= MAX_REQUESTS:
        return None
    if len(values) != 2 + count + request_count:
        return None
    current = list(values[2:2 + count])
    if sorted(current) != list(range(count)):
        return None
    requests = values[2 + count:]
    if any(item < 0 or item >= count for item in requests):
        return None
    return count, current, requests


def _replay(count: int, current: list[int], requests: Sequence[int]) -> list[int]:
    position_of = [0] * count
    for position, item in enumerate(current):
        position_of[item] = position
    access_positions = []
    total = 0
    for item in requests:
        position = position_of[item]
        access_positions.append(position + 1)
        total += position + 1
        if position != 0:
            preceding = current[position - 1]
            current[position - 1], current[position] = item, preceding
            position_of[item] = position - 1
            position_of[preceding] = position
            total += 1
    return [total, *current, *access_positions]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    count, current, requests = decoded
    words = _replay(count, current, requests)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
