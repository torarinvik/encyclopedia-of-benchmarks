"""Deterministic Havel-Hakimi construction for small simple graphs."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 8
MAX_VALID_INPUT_LENGTH = 9
MAX_INPUT_LENGTH = 10
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_OUTPUT_BYTES = 8 * (2 + 2 * MAX_EDGES)
WORKSPACE_BYTES = 2048
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n = values[0]
    if not 0 <= n <= MAX_VERTICES or len(values) != n + 1:
        return None
    degrees = list(values[1:])
    if any(not 0 <= degree < n for degree in degrees):
        return None
    return degrees


def _construct(degrees_input: list[int]) -> list[int] | None:
    n = len(degrees_input)
    residual = degrees_input.copy()
    active = [True] * n
    edges: list[tuple[int, int]] = []

    while True:
        hub = -1
        for vertex in range(n):
            if not active[vertex] or residual[vertex] == 0:
                continue
            if (hub < 0 or residual[vertex] > residual[hub]
                    or (residual[vertex] == residual[hub] and vertex < hub)):
                hub = vertex
        if hub < 0:
            break

        degree = residual[hub]
        residual[hub] = 0
        active[hub] = False
        candidates = [vertex for vertex in range(n) if active[vertex]]
        candidates.sort(key=lambda vertex: (-residual[vertex], vertex))
        if degree > len(candidates):
            return None
        for neighbor in candidates[:degree]:
            if residual[neighbor] == 0:
                return None
            residual[neighbor] -= 1
            edges.append((min(hub, neighbor), max(hub, neighbor)))

    words = [1, len(edges)]
    for left, right in edges:
        words.extend((left, right))
    return words


def _encode(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    degrees = _parse(values, input_length, input_is_null)
    if degrees is None:
        return -1, b""
    words = _construct(degrees)
    if words is None:
        words = [0]
    encoded = _encode(words)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > actual_capacity:
        return -2, b""
    return len(encoded), encoded
