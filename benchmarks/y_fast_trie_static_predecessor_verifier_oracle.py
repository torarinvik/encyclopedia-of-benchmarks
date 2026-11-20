"""Independent sorted-array oracle for strict static predecessor/successor queries."""

from __future__ import annotations

from bisect import bisect_left, bisect_right
from collections.abc import Sequence

MAX_KEYS = 256
MAX_QUERIES = 256
MAX_VALID_INPUT_LENGTH = 2 + MAX_KEYS + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _read_case(values: Sequence[int] | None, input_is_null: bool,
               input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if input_is_null is not False or not isinstance(values, (tuple, list)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 2
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    key_count, query_count = values[0], values[1]
    if (type(key_count) is not int or type(query_count) is not int
            or not 0 <= key_count <= MAX_KEYS or not 0 <= query_count <= MAX_QUERIES):
        return None
    if actual_length != 2 + key_count + query_count:
        return None
    keys = tuple(values[2:2 + key_count])
    queries = tuple(values[2 + key_count:])
    if any(type(key) is not int or not 0 <= key <= 65535 for key in keys):
        return None
    if any(type(query) is not int or not 0 <= query <= 65535 for query in queries):
        return None
    if len(set(keys)) != len(keys):
        return None
    return tuple(sorted(keys)), queries


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read_case(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    keys, queries = parsed
    total = 0
    for index, query in enumerate(queries, start=1):
        predecessor_position = bisect_left(keys, query) - 1
        successor_position = bisect_right(keys, query)
        predecessor_plus_one = keys[predecessor_position] + 1 if predecessor_position >= 0 else 0
        successor_plus_one = keys[successor_position] + 1 if successor_position < len(keys) else 0
        total += index * (predecessor_plus_one + 65537 * successor_plus_one)
    return total
