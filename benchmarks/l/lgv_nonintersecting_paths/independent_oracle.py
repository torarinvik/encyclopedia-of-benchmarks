"""Directly enumerate disjoint monotone paths for the LGV fixtures."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_HEIGHT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATHS,
    MAX_WIDTH,
)


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 4:
        return None
    height, width, path_count, blocked = values[:4]
    if (not 1 <= height <= MAX_HEIGHT or not 2 <= width <= MAX_WIDTH
            or not 1 <= path_count <= min(MAX_PATHS, height)
            or not 0 <= blocked < (1 << (height * width))
            or len(values) != 4 + 2 * path_count):
        return None
    sources = list(values[4:4 + path_count])
    sinks = list(values[4 + path_count:])
    if (any(not 0 <= row < height for row in sources + sinks)
            or any(sources[index] >= sources[index + 1]
                   for index in range(path_count - 1))
            or any(sinks[index] >= sinks[index + 1]
                   for index in range(path_count - 1))
            or any(sources[index] > sinks[index]
                   for index in range(path_count))):
        return None
    for row in sources:
        if blocked >> (row * width) & 1:
            return None
    for row in sinks:
        if blocked >> (row * width + width - 1) & 1:
            return None
    return height, width, path_count, blocked, sources, sinks


def _enumerate_paths(height: int, width: int, blocked: int,
                     source_row: int, sink_row: int) -> list[tuple[int, ...]]:
    paths: list[tuple[int, ...]] = []
    target = sink_row * width + width - 1

    def visit(row: int, column: int, vertices: list[int]) -> None:
        vertex = row * width + column
        if vertex == target:
            paths.append(tuple(vertices))
            return
        if column + 1 < width:
            next_vertex = vertex + 1
            if not (blocked >> next_vertex & 1):
                vertices.append(next_vertex)
                visit(row, column + 1, vertices)
                vertices.pop()
        if row + 1 <= sink_row:
            next_vertex = vertex + width
            if not (blocked >> next_vertex & 1):
                vertices.append(next_vertex)
                visit(row + 1, column, vertices)
                vertices.pop()

    start = source_row * width
    visit(source_row, 0, [start])
    return paths


def _count_disjoint(height: int, width: int, blocked: int,
                    sources: list[int], sinks: list[int]) -> int:
    choices = [
        _enumerate_paths(height, width, blocked, source, sink)
        for source, sink in zip(sources, sinks)
    ]

    def choose(index: int, occupied: set[int]) -> int:
        if index == len(choices):
            return 1
        total = 0
        for path in choices[index]:
            if occupied.isdisjoint(path):
                occupied.update(path)
                total += choose(index + 1, occupied)
                occupied.difference_update(path)
        return total

    return choose(0, set())


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    height, width, _, blocked, sources, sinks = decoded
    return _count_disjoint(height, width, blocked, sources, sinks)
