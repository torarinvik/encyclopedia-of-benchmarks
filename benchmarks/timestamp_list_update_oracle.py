"""Primary bounded oracle for Timestamp online list update."""

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
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= count <= MAX_REQUESTS or len(values) != 2 + n + count:
        return None
    order = list(values[2:2 + n])
    requests = tuple(values[2 + n:])
    if sorted(order) != list(range(n)) or any(not 0 <= page < n for page in requests):
        return None
    return order, requests


def _run(order: list[int], requests: tuple[int, ...]) -> list[int]:
    last_request = [-1] * len(order)
    positions: list[int] = []
    total = 0
    for time, page in enumerate(requests):
        position = order.index(page)
        positions.append(position + 1)
        total += position + 1
        previous_time = last_request[page]
        if previous_time >= 0:
            for target, candidate in enumerate(order[:position]):
                if requests[previous_time + 1:time].count(candidate) <= 1:
                    order.pop(position)
                    order.insert(target, page)
                    break
        last_request[page] = time
    return [total, *order, *positions]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    order, requests = parsed
    words = _run(order, requests)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
