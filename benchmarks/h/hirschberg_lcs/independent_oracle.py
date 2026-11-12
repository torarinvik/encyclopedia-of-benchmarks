"""Independent full-table LCS certificate verifier."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import MAX_PARSEABLE_LENGTH, MAX_SEQUENCE_LENGTH, expected_output as _primary_output
except ImportError:  # Direct import from the package directory.
    from primary_oracle import MAX_PARSEABLE_LENGTH, MAX_SEQUENCE_LENGTH, expected_output as _primary_output


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, m = values[:2]
    if not 0 <= n <= MAX_SEQUENCE_LENGTH or not 0 <= m <= MAX_SEQUENCE_LENGTH:
        return None
    if len(values) != 2 + n + m:
        return None
    first = tuple(values[2:2 + n])
    second = tuple(values[2 + n:])
    if any(not 0 <= value <= 127 for value in first + second):
        return None
    return first, second


def _optimal_length(first: Sequence[int], second: Sequence[int]) -> int:
    table = [[0] * (len(second) + 1) for _ in range(len(first) + 1)]
    for i, a in enumerate(first, 1):
        for j, b in enumerate(second, 1):
            if a == b:
                table[i][j] = table[i - 1][j - 1] + 1
            else:
                table[i][j] = max(table[i - 1][j], table[i][j - 1])
    return table[-1][-1]


def _is_subsequence(candidate: bytes, source: Sequence[int]) -> bool:
    position = 0
    for symbol in source:
        if position < len(candidate) and candidate[position] == symbol:
            position += 1
    return position == len(candidate)


def verify_output(
    values: Sequence[int] | None,
    result: int,
    payload: bytes,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and payload == b""
    if type(output_is_null) is not bool or capacity is not None and (type(capacity) is not int or capacity < 0):
        return result == -1 and payload == b""
    if output_is_null or capacity is not None and capacity < 0:
        return result == -2 and payload == b""
    first, second = parsed
    if result != len(payload) or capacity is not None and capacity < result:
        return result == -2 and payload == b""
    return (
        len(payload) == _optimal_length(first, second)
        and _is_subsequence(payload, first)
        and _is_subsequence(payload, second)
    )


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the exact primary bytes, independently checking certificate validity."""
    result, payload = _primary_output(
        values,
        capacity=capacity,
        output_is_null=output_is_null,
        input_is_null=input_is_null,
        input_length=input_length,
    )
    if not verify_output(
        values,
        result,
        payload,
        capacity=capacity,
        output_is_null=output_is_null,
        input_is_null=input_is_null,
        input_length=input_length,
    ):
        raise ValueError("Hirschberg primary output failed independent full-table certificate validation")
    return result, payload
