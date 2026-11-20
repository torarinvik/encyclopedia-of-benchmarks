"""Independent incidence-matrix reference for the bounded encoding."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 12
MAX_PARSEABLE_INPUT_LENGTH = 111
MAX_OUTPUT_BYTES = 1712


def _read(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    incidence = [[False] * m for _ in range(n)]
    offset = 2
    for edge_id in range(m):
        if offset >= len(values):
            return None
        size = values[offset]
        offset += 1
        if size < 0 or size > n or offset + size > len(values):
            return None
        for vertex in values[offset:offset + size]:
            if vertex < 0 or vertex >= n or incidence[vertex][edge_id]:
                return None
            incidence[vertex][edge_id] = True
        offset += size
    if offset != len(values):
        return None
    return n, incidence


def _encode(n: int, incidence: Sequence[Sequence[bool]]) -> bytes:
    m = len(incidence[0]) if n else 0
    incidence_count = sum(sum(row) for row in incidence)
    words = [n + m, incidence_count]
    words += [0] * n
    words += [1] * m
    for vertex in range(n):
        for edge_id in range(m):
            if incidence[vertex][edge_id]:
                words += [vertex, n + edge_id]
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    payload = _encode(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
