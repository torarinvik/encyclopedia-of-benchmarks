"""Primary oracle for bounded all-pairs min-plus repeated squaring."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 512
INF = 1_000_000


def _parse(values: Sequence[int] | None) -> tuple[int, list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    matrix = list(values[1:])
    for i in range(n):
        for j in range(n):
            value = matrix[i * n + j]
            if i == j:
                if value != 0:
                    return None
            elif value != INF and not 1 <= value <= 1000:
                return None
    return n, matrix


def _square(matrix: list[int], n: int) -> list[int]:
    product = [INF] * (n * n)
    for i in range(n):
        for j in range(n):
            best = INF
            for k in range(n):
                left, right = matrix[i * n + k], matrix[k * n + j]
                if left != INF and right != INF and left + right < best:
                    best = left + right
            product[i * n + j] = best
    return product


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, distances = parsed
    edge_bound = 1
    while edge_bound < n - 1:
        distances = _square(distances, n)
        edge_bound *= 2
    raw = b"".join(value.to_bytes(8, "little", signed=True) for value in distances)
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
