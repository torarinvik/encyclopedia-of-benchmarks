"""Lexicographic bounded Bondy–Chvátal closure profile."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 8
MAX_EDGES = 28
MAX_VALID_INPUT_LENGTH = 58
MAX_PARSEABLE_INPUT_LENGTH = 59
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 1024
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES:
        return None
    if not 0 <= m <= min(MAX_EDGES, n * (n - 1) // 2):
        return None
    if len(values) != 2 + 2 * m:
        return None
    rows = [0] * n
    for offset in range(2, len(values), 2):
        u, v = values[offset], values[offset + 1]
        if not (0 <= u < n and 0 <= v < n) or u == v:
            return None
        if rows[u] & (1 << v):
            return None
        rows[u] |= 1 << v
        rows[v] |= 1 << u
    return n, m, rows


def _close(n: int, rows: list[int]) -> tuple[int, ...]:
    added = 0
    while True:
        degree = [row.bit_count() for row in rows]
        chosen: tuple[int, int] | None = None
        for u in range(n):
            for v in range(u + 1, n):
                if rows[u] & (1 << v):
                    continue
                if degree[u] + degree[v] >= n:
                    chosen = (u, v)
                    break
            if chosen is not None:
                break
        if chosen is None:
            break
        u, v = chosen
        rows[u] |= 1 << v
        rows[v] |= 1 << u
        added += 1

    complete_mask = (1 << n) - 1
    is_complete = all(rows[u] == (complete_mask ^ (1 << u)) for u in range(n))
    return (int(is_complete), added, *rows)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, b""
    n, _, rows = decoded
    words = _close(n, rows)
    staged = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
