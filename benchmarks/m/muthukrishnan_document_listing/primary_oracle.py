"""Sparse-table reference for bounded Muthukrishnan document listing."""

from __future__ import annotations

from typing import Sequence

MIN_N = 1
MAX_N = 32
MIN_DOCUMENTS = 1
MAX_DOCUMENTS = 8
MIN_QUERIES = 1
MAX_QUERIES = 16
MAX_VALID_INPUT_LENGTH = 3 + MAX_N + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_QUERIES * (1 + MAX_DOCUMENTS)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, input_length: int | None):
    if values is None:
        return None
    try:
        actual = len(values)
    except (TypeError, ValueError, OverflowError):
        return None
    length = actual if input_length is None else input_length
    if isinstance(length, bool) or not isinstance(length, int):
        return None
    if length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH or length != actual:
        return None
    n, documents, queries = values[0], values[1], values[2]
    if any(isinstance(x, bool) or not isinstance(x, int) for x in (n, documents, queries)):
        return None
    if not MIN_N <= n <= MAX_N or not MIN_DOCUMENTS <= documents <= MAX_DOCUMENTS:
        return None
    if not MIN_QUERIES <= queries <= MAX_QUERIES or length != 3 + n + 2 * queries:
        return None
    da = list(values[3:3 + n])
    if any(isinstance(x, bool) or not isinstance(x, int) or not 0 <= x < documents for x in da):
        return None
    intervals = []
    offset = 3 + n
    for query in range(queries):
        lo, hi = values[offset + 2 * query:offset + 2 * query + 2]
        if any(isinstance(x, bool) or not isinstance(x, int) for x in (lo, hi)):
            return None
        if not 0 <= lo <= hi < n:
            return None
        intervals.append((lo, hi))
    return n, documents, da, intervals


def _better(left: int, right: int, previous: list[int]) -> int:
    if left < 0:
        return right
    if right < 0:
        return left
    if previous[left] != previous[right]:
        return left if previous[left] < previous[right] else right
    return left if left < right else right


def _build_sparse(previous: list[int]) -> tuple[list[int], list[list[int]]]:
    n = len(previous)
    logs = [0] * (n + 1)
    for size in range(2, n + 1):
        logs[size] = logs[size // 2] + 1
    levels = logs[n] + 1
    table = [[-1] * n for _ in range(levels)]
    table[0] = list(range(n))
    for level in range(1, levels):
        width = 1 << level
        half = width >> 1
        for start in range(n - width + 1):
            table[level][start] = _better(
                table[level - 1][start],
                table[level - 1][start + half],
                previous,
            )
    return logs, table


def build(values: Sequence[int]) -> bytes:
    parsed = _parse(values, None)
    if parsed is None:
        raise ValueError("invalid bounded document-listing input")
    n, documents, da, intervals = parsed
    last = [-1] * documents
    previous = [-1] * n
    for index, document in enumerate(da):
        previous[index] = last[document]
        last[document] = index
    logs, table = _build_sparse(previous)

    def range_min(lo: int, hi: int) -> int:
        level = logs[hi - lo + 1]
        width = 1 << level
        return _better(table[level][lo], table[level][hi - width + 1], previous)

    out = bytearray()
    for original_lo, hi in intervals:
        count_position = len(out)
        out.append(0)
        witnesses: list[tuple[int, int]] = []

        def visit(lo: int, right: int) -> None:
            if lo > right:
                return
            index = range_min(lo, right)
            if previous[index] >= original_lo:
                return
            witnesses.append((index, da[index]))
            visit(lo, index - 1)
            visit(index + 1, right)

        visit(original_lo, hi)
        witnesses.sort(key=lambda item: item[0])
        out[count_position] = len(witnesses)
        out.extend(document for _, document in witnesses)
    return bytes(out)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    encoded = build(values)
    if output_is_null:
        return -2, b""
    if capacity is not None and (
        isinstance(capacity, bool) or not isinstance(capacity, int) or capacity < len(encoded)
    ):
        return -2, b""
    return len(encoded), encoded
