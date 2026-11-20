"""Direct subtree-set oracle for the bounded tree sack benchmark."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = 8 * MAX_N
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...], tuple[int, ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or input_length != 2 * n:
        return None
    parents = tuple(values[1:n])
    colors = tuple(values[n:2 * n])
    if any(not 0 <= parents[v - 1] < v for v in range(1, n)):
        return None
    if any(not 0 <= color <= 255 for color in colors):
        return None
    return n, parents, colors


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    n, parents, colors = parsed
    required = 8 * n
    effective_capacity = required if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < required or output_is_null):
        return CAPACITY_ERROR, b""

    children = [[] for _ in range(n)]
    for vertex, parent in enumerate(parents, 1):
        children[parent].append(vertex)
    answers = [0] * n
    for root in range(n):
        pending = [root]
        found: set[int] = set()
        while pending:
            vertex = pending.pop()
            found.add(colors[vertex])
            pending.extend(children[vertex])
        answers[root] = len(found)
    payload = b"".join(struct.pack("<q", count) for count in answers)
    return len(payload), payload


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
