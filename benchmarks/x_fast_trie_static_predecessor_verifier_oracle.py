"""Independent sorted-array oracle for the static predecessor checksum."""

from __future__ import annotations

from bisect import bisect_right
from collections.abc import Sequence

MAX_KEYS = 24
MAX_QUERIES = 24
MAX_VALID_INPUT_LENGTH = 2 + MAX_KEYS + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _read_case(values: Sequence[int] | None, input_is_null: bool,
               input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if input_is_null is not False or not isinstance(values, (tuple, list)):
        return None
    n_values = len(values) if input_length is None else input_length
    if type(n_values) is not int or n_values < 2 or n_values > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if n_values != len(values) or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    n, q = values[0], values[1]
    if type(n) is not int or type(q) is not int or not 0 <= n <= MAX_KEYS or not 0 <= q <= MAX_QUERIES:
        return None
    if n_values - 2 != n + q:
        return None
    keys = tuple(values[2:2 + n])
    queries = tuple(values[2 + n:])
    if any(type(k) is not int or k < 0 or k > 65535 for k in keys):
        return None
    if any(type(x) is not int or x < 0 or x > 65535 for x in queries):
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
    for one_based_index, query in enumerate(queries, start=1):
        position = bisect_right(keys, query)
        predecessor_plus_one = keys[position - 1] + 1 if position else 0
        total += one_based_index * predecessor_plus_one
    return total
