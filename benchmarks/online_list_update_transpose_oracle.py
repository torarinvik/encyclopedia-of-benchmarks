"""Primary bounded oracle for the Transpose online list-update rule."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_REQUESTS = 32
MAX_INPUT_LENGTH = 42
MAX_OUTPUT_BYTES = 328
MAX_WORKSPACE_BYTES = 2048


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, request_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= request_count <= MAX_REQUESTS:
        return None
    if len(values) != 2 + n + request_count:
        return None
    initial = list(values[2:2 + n])
    requests = list(values[2 + n:])
    if sorted(initial) != list(range(n)) or any(not 0 <= item < n for item in requests):
        return None
    return n, initial, requests


def _run(order: list[int], requests: list[int]) -> list[int]:
    total_cost = 0
    access_positions = []
    for item in requests:
        position = order.index(item)
        access_positions.append(position + 1)
        total_cost += position + 1
        if position > 0:
            order[position - 1], order[position] = order[position], order[position - 1]
            total_cost += 1
    return [total_cost, *order, *access_positions]


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    _, order, requests = parsed
    words = _run(order, requests)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
