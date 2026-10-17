"""Independent oracle for the bounded Java Mo's algorithm benchmark."""

from __future__ import annotations

MAX_N = 256
MAX_Q = 256
MAX_INPUT_LENGTH = 4 + MAX_N + 3 * MAX_Q + 1
VALUE_MIN = -1_000_000
VALUE_MAX = 1_000_000
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _fnv1a_result_stream(op: int, query_count: int, results: list[int]) -> int:
    """Hash op:u8, q:u16-le, and signed-i32 results in original order."""
    payload = bytearray((op,))
    payload.extend(query_count.to_bytes(2, "little", signed=False))
    for result in results:
        payload.extend(result.to_bytes(4, "little", signed=True))

    digest = FNV_OFFSET
    for byte in payload:
        digest = ((digest ^ byte) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the framed result hash, or -1 for an invalid trace."""
    if (
        not isinstance(values, (list, tuple))
        or not 4 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1

    op, n, q, target = values[:4]
    if op not in (0, 1) or not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return -1
    if len(values) != 4 + n + 3 * q:
        return -1
    if not VALUE_MIN <= target <= VALUE_MAX:
        return -1

    array = values[4 : 4 + n]
    if any(not VALUE_MIN <= value <= VALUE_MAX for value in array):
        return -1

    queries: list[tuple[int, int, int]] = []
    seen_indices: set[int] = set()
    offset = 4 + n
    for query_number in range(q):
        left, right, index = values[offset + 3 * query_number : offset + 3 * query_number + 3]
        if not (0 <= left <= right < n) or not 0 <= index < q or index in seen_indices:
            return -1
        seen_indices.add(index)
        queries.append((left, right, index))
    if len(seen_indices) != q:
        return -1

    results = [0] * q
    for left, right, index in queries:
        window = array[left : right + 1]
        if op == 0:
            results[index] = sum(window)
        else:
            results[index] = sum(value == target for value in window)

    return _fnv1a_result_stream(op, q, results)
