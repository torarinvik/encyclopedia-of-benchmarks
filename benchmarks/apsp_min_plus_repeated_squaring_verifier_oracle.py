"""Independent Floyd--Warshall verifier for repeated-squaring APSP output."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 65
INF = 1_000_000


def _decode(values: Sequence[int] | None) -> tuple[int, list[list[int]]] | None:
    if (not isinstance(values, (tuple, list)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= 8 or len(values) != 1 + n * n:
        return None
    matrix = [list(values[1 + row * n:1 + (row + 1) * n]) for row in range(n)]
    for row in range(n):
        for column in range(n):
            distance = matrix[row][column]
            if row == column:
                if distance != 0:
                    return None
            elif distance != INF and not 1 <= distance <= 1000:
                return None
    return n, matrix


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, distance = decoded
    for middle in range(n):
        for source in range(n):
            if distance[source][middle] == INF:
                continue
            for target in range(n):
                if distance[middle][target] == INF:
                    continue
                candidate = distance[source][middle] + distance[middle][target]
                if candidate < distance[source][target]:
                    distance[source][target] = candidate
    raw = b"".join(distance[row][column].to_bytes(8, "little", signed=True)
                   for row in range(n) for column in range(n))
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
