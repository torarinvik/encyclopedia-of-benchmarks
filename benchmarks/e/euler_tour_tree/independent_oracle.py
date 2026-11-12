"""Breadth-first component discovery as an independent forest oracle."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N, OUTPUT_ERROR,
    )
except ImportError:
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N, OUTPUT_ERROR,
    )


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) < 2 + n:
        return None
    weights = list(values[2:2 + n])
    if any(not -100 <= weight <= 100 for weight in weights):
        return None
    cursor = 2 + n
    operations = []
    query_count = 0
    for _ in range(m):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        if kind in (0, 1):
            if cursor + 3 > len(values):
                return None
            u, v = values[cursor + 1], values[cursor + 2]
            if not 0 <= u < n or not 0 <= v < n or u == v:
                return None
            operations.append((kind, u, v))
            cursor += 3
        elif kind == 2:
            if cursor + 3 > len(values):
                return None
            vertex, weight = values[cursor + 1], values[cursor + 2]
            if not 0 <= vertex < n or not -100 <= weight <= 100:
                return None
            operations.append((kind, vertex, weight))
            cursor += 3
        elif kind == 3:
            if cursor + 2 > len(values):
                return None
            vertex = values[cursor + 1]
            if not 0 <= vertex < n:
                return None
            operations.append((kind, vertex))
            query_count += 1
            cursor += 2
        else:
            return None
    if cursor != len(values) or query_count == 0:
        return None
    graph = [set() for _ in range(n)]
    for operation in operations:
        if operation[0] == 0:
            _, u, v = operation
            stack = [u]
            seen = {u}
            while stack:
                for neighbor in graph[stack.pop()]:
                    if neighbor not in seen:
                        seen.add(neighbor)
                        stack.append(neighbor)
            if v in seen:
                return None
            graph[u].add(v)
            graph[v].add(u)
        elif operation[0] == 1:
            _, u, v = operation
            if v not in graph[u]:
                return None
            graph[u].remove(v)
            graph[v].remove(u)
    return n, weights, operations, query_count


def _run(n: int, weights: list[int], operations) -> list[int]:
    graph = [set() for _ in range(n)]
    values = list(weights)
    answers = []
    for operation in operations:
        kind = operation[0]
        if kind == 0:
            _, u, v = operation
            graph[u].add(v)
            graph[v].add(u)
        elif kind == 1:
            _, u, v = operation
            graph[u].remove(v)
            graph[v].remove(u)
        elif kind == 2:
            _, vertex, value = operation
            values[vertex] = value
        else:
            start = operation[1]
            seen = {start}
            stack = [start]
            total = 0
            while stack:
                vertex = stack.pop()
                total += values[vertex]
                for neighbor in graph[vertex]:
                    if neighbor not in seen:
                        seen.add(neighbor)
                        stack.append(neighbor)
            answers.extend((len(seen), total))
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    n, weights, operations, query_count = parsed
    required = 16 * query_count
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    answers = _run(n, weights, operations)
    return required, b"".join(struct.pack("<q", answer) for answer in answers)
