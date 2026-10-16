"""Portable membership-trace contract for separate-chaining hash tables."""

from __future__ import annotations

MAX_BUCKETS = 127
MAX_OPERATIONS = 128
MAX_QUERIES = 63
MAX_KEY = (1 << 31) - 1
# One extra pair is accepted by the verifier to test the over-bound operation count.
MAX_INPUT_LENGTH = 2 + 2 * (MAX_OPERATIONS + 1)


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1

    modulus, operation_count = values[:2]
    if not 1 <= modulus <= MAX_BUCKETS or not 0 <= operation_count <= MAX_OPERATIONS:
        return -1
    if len(values) != 2 + 2 * operation_count:
        return -1

    buckets: list[list[int]] = [[] for _ in range(modulus)]
    result = 0
    query_count = 0
    offset = 2
    for _ in range(operation_count):
        operation, key = values[offset:offset + 2]
        offset += 2
        if operation not in (0, 1) or not 0 <= key <= MAX_KEY:
            return -1
        bucket = buckets[key % modulus]
        if operation == 0:
            bucket.append(key)
        else:
            if query_count >= MAX_QUERIES:
                return -1
            if key in bucket:
                result |= 1 << query_count
            query_count += 1
    return result
