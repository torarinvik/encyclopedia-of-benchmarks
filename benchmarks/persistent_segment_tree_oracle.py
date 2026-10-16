"""Naive-array oracle for persistent point updates and historical range sums."""

from __future__ import annotations

MAX_N = 64
MAX_Q = 64
MAX_VALUE = 1000
MAX_INPUT_LENGTH = 2 + MAX_N + 4 * MAX_Q
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _hash_i64_words(words: list[int]) -> int:
    digest = FNV_OFFSET
    for value in words:
        bits = value & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK64
    return digest & MASK63


def expected_result(packed: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(packed, (list, tuple)) or len(packed) < 3
            or len(packed) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in packed)):
        return -1
    n, operation_count = packed[:2]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_Q:
        return -1
    expected_length = 2 + n + 4 * operation_count
    if len(packed) != expected_length:
        return -1
    initial = list(packed[2:2 + n])
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in initial):
        return -1

    versions = [initial]
    query_sums: list[int] = []
    offset = 2 + n
    for _ in range(operation_count):
        opcode, a, b, c = packed[offset:offset + 4]
        offset += 4
        if opcode == 0:
            if not 0 <= a < len(versions) or not 0 <= b < n or not -MAX_VALUE <= c <= MAX_VALUE:
                return -1
            next_version = versions[a].copy()
            next_version[b] = c
            versions.append(next_version)
        elif opcode == 1:
            if not 0 <= a < len(versions) or not 0 <= b <= c < n:
                return -1
            query_sums.append(sum(versions[a][b:c + 1]))
        else:
            return -1
    return _hash_i64_words([len(versions), len(query_sums), *query_sums])
