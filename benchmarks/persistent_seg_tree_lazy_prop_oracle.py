"""Independent oracle for persistent range-add/range-sum operation traces."""

from __future__ import annotations

MAX_N = 64
MAX_Q = 64
MAX_INPUT_LENGTH = 2 + MAX_N + 4 * MAX_Q + 1
VALUE_MIN = -1_000
VALUE_MAX = 1_000
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _fnv_i64_words(words: list[int]) -> int:
    digest = FNV_OFFSET
    for word in words:
        for byte in (word & MASK64).to_bytes(8, "little", signed=False):
            digest = ((digest ^ byte) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the operation-trace hash, or -1 when the input is invalid."""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1

    n64, q64 = values[:2]
    if not 1 <= n64 <= MAX_N or not 0 <= q64 <= MAX_Q:
        return -1
    n = n64
    q = q64
    if len(values) != 2 + n + 4 * q:
        return -1

    initial = list(values[2 : 2 + n])
    if any(value < VALUE_MIN or value > VALUE_MAX for value in initial):
        return -1

    versions = [initial]
    query_sums: list[int] = []
    offset = 2 + n
    for operation_index in range(q):
        operation, a, b, c = values[offset + 4 * operation_index : offset + 4 * operation_index + 4]
        if operation == 0:
            left, right, delta = a, b, c
            if not (0 <= left <= right < n) or not VALUE_MIN <= delta <= VALUE_MAX:
                return -1
            next_version = versions[-1].copy()
            for index in range(left, right + 1):
                next_version[index] += delta
            versions.append(next_version)
        elif operation == 1:
            version, left, right = a, b, c
            if not (0 <= version < len(versions)) or not (0 <= left <= right < n):
                return -1
            query_sums.append(sum(versions[version][left : right + 1]))
        else:
            return -1

    return _fnv_i64_words([len(versions), len(query_sums), *query_sums])
