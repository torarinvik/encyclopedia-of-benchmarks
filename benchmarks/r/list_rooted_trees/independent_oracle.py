"""Prüfer-sequence reference, independent of the multiset generator."""

from __future__ import annotations

import heapq
import itertools

from .primary_oracle import MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_VERTICES:
        return None
    return values[0]


def _canonical(adjacency: list[list[int]], node: int, parent: int) -> bytes:
    children = sorted(_canonical(adjacency, child, node)
                      for child in adjacency[node] if child != parent)
    return b"(" + b"".join(children) + b")"


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    size = _decode(values, input_is_null, input_length)
    if size is None:
        return -1, b""
    if size == 1:
        shapes = [b"()"]
    else:
        found: set[bytes] = set()
        for sequence in itertools.product(range(size), repeat=size - 2):
            degree = [1] * size
            for vertex in sequence:
                degree[vertex] += 1
            leaves = [vertex for vertex, value in enumerate(degree) if value == 1]
            heapq.heapify(leaves)
            adjacency = [[] for _ in range(size)]
            for vertex in sequence:
                leaf = heapq.heappop(leaves)
                adjacency[leaf].append(vertex)
                adjacency[vertex].append(leaf)
                degree[leaf] -= 1
                degree[vertex] -= 1
                if degree[vertex] == 1:
                    heapq.heappush(leaves, vertex)
            left, right = heapq.heappop(leaves), heapq.heappop(leaves)
            adjacency[left].append(right)
            adjacency[right].append(left)
            found.add(_canonical(adjacency, 0, -1))
        shapes = sorted(found)
    output = bytearray((len(shapes) & 255, len(shapes) >> 8))
    for shape in shapes:
        output.extend(shape)
    return len(output), bytes(output)
