"""Independent position-map verifier for the Bit list-update policy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_REQUESTS = 32
MAX_INPUT_LENGTH = 50


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values)):
        return None
    n, count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= count <= MAX_REQUESTS or len(values) != 2 + 2 * n + count:
        return None
    order = list(values[2:2 + n])
    requests = tuple(values[2 + n:2 + n + count])
    bits = list(values[2 + n + count:])
    if sorted(order) != list(range(n)) or any(page < 0 or page >= n for page in requests) or any(bit not in (0, 1) for bit in bits):
        return None
    return order, requests, bits


def _verify(order: list[int], requests: tuple[int, ...], bits: list[int]) -> list[int]:
    position_of = [0] * len(order)
    for position, page in enumerate(order):
        position_of[page] = position
    positions: list[int] = []
    total = 0
    for page in requests:
        position = position_of[page]
        positions.append(position + 1)
        total += position + 1
        bits[page] ^= 1
        if bits[page]:
            for shift in range(position, 0, -1):
                displaced = order[shift - 1]
                order[shift] = displaced
                position_of[displaced] = shift
            order[0] = page
            position_of[page] = 0
    return [total, *order, *positions, *bits]


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
    order, requests, bits = decoded
    words = _verify(order, requests, bits)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
