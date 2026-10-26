"""Independent direct-predecessor verifier for permutation query workloads."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_QUERIES = 16
MAX_INPUT_LENGTH = 52


def _validated(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, stride = values[0], values[1]
    if n < 1 or n > MAX_N or stride < 1 or stride > MAX_N:
        return None
    q_at = 2 + n
    if len(values) <= q_at:
        return None
    query_count = values[q_at]
    if query_count < 0 or query_count > MAX_QUERIES or len(values) != q_at + 1 + 2 * query_count:
        return None
    permutation = values[2:q_at]
    if len(set(permutation)) != n or set(permutation) != set(range(1, n + 1)):
        return None
    queries = []
    for offset in range(q_at + 1, len(values), 2):
        operation, index = values[offset], values[offset + 1]
        if operation not in (0, 1) or index < 1 or index > n:
            return None
        queries.append((operation, index))
    return n, tuple(permutation), queries


def _direct_answers(n: int, permutation: Sequence[int], queries):
    predecessor = [0] * (n + 1)
    for index, value in enumerate(permutation, start=1):
        predecessor[value] = index
    return [permutation[index - 1] if operation == 0 else predecessor[index]
            for operation, index in queries]


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
    parsed = _validated(values)
    if parsed is None:
        return -1, b""
    n, permutation, queries = parsed
    answers = _direct_answers(n, permutation, queries)
    payload = struct.pack("<" + "q" * len(answers), *answers) if answers else b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
