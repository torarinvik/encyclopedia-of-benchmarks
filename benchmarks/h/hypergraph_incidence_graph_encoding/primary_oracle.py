"""Bounded deterministic hypergraph-to-incidence-graph encoding."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 12
MAX_VALID_INPUT_LENGTH = 2 + MAX_M * (MAX_N + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_NODES = MAX_N + MAX_M
MAX_INCIDENCES = MAX_N * MAX_M
MAX_OUTPUT_BYTES = 8 * (2 + MAX_NODES + 2 * MAX_INCIDENCES)


def _parse(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    edges: list[list[int]] = []
    offset = 2
    for _ in range(m):
        if offset >= len(values):
            return None
        size = values[offset]
        offset += 1
        if not 0 <= size <= n or offset + size > len(values):
            return None
        vertices = list(values[offset:offset + size])
        if (any(not 0 <= vertex < n for vertex in vertices)
                or len(set(vertices)) != size):
            return None
        edges.append(vertices)
        offset += size
    if offset != len(values):
        return None
    return n, edges


def _encode(n: int, edges: list[list[int]]) -> bytes:
    m = len(edges)
    words = [n + m, sum(len(edge) for edge in edges)]
    words.extend([0] * n)
    words.extend([1] * m)
    for vertex in range(n):
        for edge_id, edge in enumerate(edges):
            if vertex in edge:
                words.extend((vertex, n + edge_id))
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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _encode(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
