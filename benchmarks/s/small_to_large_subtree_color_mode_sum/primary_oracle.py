"""Small-to-large frequency-map oracle for bounded rooted trees."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VERTICES = 64
MAX_VALID_INPUT_LENGTH = 128
MAX_INPUT_LENGTH = 129
MAX_OUTPUT_BYTES = 8 * MAX_VERTICES


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_VERTICES or len(values) != 2 * n:
        return None
    parent = [-1] + list(values[1:n])
    if any(not 0 <= parent[v] < v for v in range(1, n)):
        return None
    colors = list(values[n:])
    if any(not -1000 <= color <= 1000 for color in colors):
        return None
    return n, parent, colors


def _small_to_large(n: int, parent: list[int], colors: list[int]) -> list[int]:
    children = [[] for _ in range(n)]
    for vertex in range(1, n):
        children[parent[vertex]].append(vertex)
    maps: list[dict[int, int] | None] = [None] * n
    answers = [0] * n
    for vertex in range(n - 1, -1, -1):
        child_maps = [maps[child] for child in children[vertex]]
        largest = max(child_maps, key=len) if child_maps else None
        current = largest if largest is not None else {}
        for child_map in child_maps:
            if child_map is largest:
                continue
            assert child_map is not None
            for color, frequency in child_map.items():
                current[color] = current.get(color, 0) + frequency
        current[colors[vertex]] = current.get(colors[vertex], 0) + 1
        maximum = max(current.values())
        answers[vertex] = sum(color for color, frequency in current.items()
                               if frequency == maximum)
        maps[vertex] = current
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    n, parent, colors = decoded
    encoded = b"".join(struct.pack("<q", answer)
                        for answer in _small_to_large(n, parent, colors))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded
