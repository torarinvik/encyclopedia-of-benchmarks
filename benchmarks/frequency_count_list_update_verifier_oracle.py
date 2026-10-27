"""Independent stable-resort verifier for Frequency Count list update."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_REQUESTS = 32
MAX_INPUT_LENGTH = 42


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values)):
        return None
    n, count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= count <= MAX_REQUESTS or len(values) != 2 + n + count:
        return None
    order = list(values[2:2 + n])
    requests = tuple(values[2 + n:])
    if sorted(order) != list(range(n)) or any(page < 0 or page >= n for page in requests):
        return None
    return order, requests


def _verify(order: list[int], requests: tuple[int, ...]) -> list[int]:
    counts = [0] * len(order)
    positions: list[int] = []
    total = 0
    for page in requests:
        positions.append(order.index(page) + 1)
        total += positions[-1]
        counts[page] += 1
        # Stable sorting retains the pre-update order among tied frequencies.
        order.sort(key=lambda candidate: -counts[candidate])
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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    order, requests = decoded
    words = _verify(order, requests)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
