"""Primary bounded oracle for the supplied-initial-bits Bit policy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_REQUESTS = 32
MAX_INPUT_LENGTH = 50
MAX_OUTPUT_BYTES = 392
MAX_WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= count <= MAX_REQUESTS or len(values) != 2 + 2 * n + count:
        return None
    order = list(values[2:2 + n])
    requests = tuple(values[2 + n:2 + n + count])
    bits = list(values[2 + n + count:])
    if (sorted(order) != list(range(n)) or any(not 0 <= page < n for page in requests)
            or any(bit not in (0, 1) for bit in bits)):
        return None
    return order, requests, bits


def _run(order: list[int], requests: tuple[int, ...], bits: list[int]) -> list[int]:
    positions: list[int] = []
    total = 0
    for page in requests:
        position = order.index(page)
        positions.append(position + 1)
        total += position + 1
        bits[page] ^= 1
        if bits[page] == 1 and position > 0:
            order.pop(position)
            order.insert(0, page)
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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    order, requests, bits = parsed
    words = _run(order, requests, bits)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
