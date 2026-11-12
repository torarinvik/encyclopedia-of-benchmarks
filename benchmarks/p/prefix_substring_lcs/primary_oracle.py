"""Semi-local prefix/substring LCS oracle with batched Fenwick sweeps."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_STRING_LENGTH = 32
MAX_QUERIES = 64
MAX_INPUT_LENGTH = 3 + 2 * MAX_STRING_LENGTH + 3 * MAX_QUERIES
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 3
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    s_length, t_length, query_count = values[:3]
    if not 1 <= s_length <= MAX_STRING_LENGTH or not 1 <= t_length <= MAX_STRING_LENGTH:
        return None
    if not 1 <= query_count <= MAX_QUERIES:
        return None
    if len(values) != 3 + s_length + t_length + 3 * query_count:
        return None

    offset = 3
    s = values[offset:offset + s_length]
    offset += s_length
    t = values[offset:offset + t_length]
    offset += t_length
    if any(not 97 <= character <= 122 for character in (*s, *t)):
        return None

    queries: list[tuple[int, int, int]] = []
    for _ in range(query_count):
        a, b, c = values[offset:offset + 3]
        offset += 3
        if not 0 <= a <= s_length or not 0 <= b <= c <= t_length:
            return None
        queries.append((a, b, c))
    return s_length, t_length, s, t, queries


def _semi_local_answers(parsed) -> list[int]:
    s_length, t_length, s, t, queries = parsed
    horizontal = [[0] * (t_length + 1) for _ in range(s_length + 1)]
    vertical = [[0] * (t_length + 1) for _ in range(s_length + 1)]
    horizontal[0] = list(range(t_length + 1))
    for i in range(1, s_length + 1):
        for j in range(1, t_length + 1):
            above = horizontal[i - 1][j]
            left = vertical[i][j - 1]
            if s[i - 1] == t[j - 1]:
                horizontal[i][j] = left
                vertical[i][j] = above
            else:
                horizontal[i][j] = max(above, left)
                vertical[i][j] = min(above, left)

    grouped: list[list[list[int]]] = [
        [[] for _ in range(t_length + 1)] for _ in range(s_length + 1)
    ]
    for query_index, (a, b, _c) in enumerate(queries):
        grouped[a][b].append(query_index)

    answers = [0] * len(queries)
    for a in range(s_length + 1):
        by_value: list[list[int]] = [[] for _ in range(t_length + 1)]
        for position, value in enumerate(horizontal[a]):
            by_value[value].append(position)
        fenwick = [0] * (t_length + 2)

        def add(position: int) -> None:
            index = position + 1
            while index < len(fenwick):
                fenwick[index] += 1
                index += index & -index

        def prefix(exclusive: int) -> int:
            total = 0
            index = exclusive
            while index > 0:
                total += fenwick[index]
                index -= index & -index
            return total

        for b in range(t_length + 1):
            for position in by_value[b]:
                add(position)
            for query_index in grouped[a][b]:
                _a, _b, c = queries[query_index]
                answers[query_index] = prefix(c + 1) - prefix(b + 1)
    return answers


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or input_is_null:
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    if (type(output_is_null) is not bool
            or capacity is not None and
                (type(capacity) is not int or capacity < 0)):
        return -1, b""
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if output_is_null or actual_capacity < 8 * len(parsed[4]):
        return -2, b""
    answers = _semi_local_answers(parsed)
    encoded = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(encoded), encoded
