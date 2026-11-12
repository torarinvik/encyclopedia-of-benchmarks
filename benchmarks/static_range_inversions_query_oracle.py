"""Bounded Mo/Fenwick oracle for strict range-inversion queries."""

import struct
from typing import Sequence

MAX_N = 128
MAX_Q = 32
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 8192
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _mo_answers(values: Sequence[int], queries: Sequence[tuple[int, int]]) -> list[int]:
    n = len(values)
    sorted_values = sorted(set(values))
    ranks = [bisect_left(sorted_values, value) for value in values]
    block = max(1, int(n ** 0.5))
    ordered = sorted(enumerate(queries), key=lambda item: (
        item[1][0] // block,
        item[1][1] if (item[1][0] // block) % 2 == 0 else -item[1][1],
        item[0],
    ))
    bit = [0] * (len(sorted_values) + 1)
    answers = [0] * len(queries)
    left = right = size = inversions = 0

    def prefix(count: int) -> int:
        total = 0
        i = count
        while i:
            total += bit[i]
            i -= i & -i
        return total

    def add(rank: int, delta: int) -> None:
        i = rank + 1
        while i < len(bit):
            bit[i] += delta
            i += i & -i

    for query_id, (target_left, target_right) in ordered:
        while left > target_left:
            left -= 1
            rank = ranks[left]
            inversions += prefix(rank)
            add(rank, 1)
            size += 1
        while right < target_right:
            rank = ranks[right]
            inversions += size - prefix(rank + 1)
            add(rank, 1)
            size += 1
            right += 1
        while left < target_left:
            rank = ranks[left]
            inversions -= prefix(rank)
            add(rank, -1)
            size -= 1
            left += 1
        while right > target_right:
            right -= 1
            rank = ranks[right]
            inversions -= size - prefix(rank + 1)
            add(rank, -1)
            size -= 1
        answers[query_id] = inversions
    return answers


def bisect_left(values: Sequence[int], target: int) -> int:
    lo, hi = 0, len(values)
    while lo < hi:
        mid = lo + (hi - lo) // 2
        if values[mid] < target:
            lo = mid + 1
        else:
            hi = mid
    return lo


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 + n + 2 * q:
        return -1, b""
    array = values[2:2 + n]
    if any(not 0 <= value <= MAX_VALUE for value in array):
        return -1, b""
    queries = []
    offset = 2 + n
    for _ in range(q):
        left, right = values[offset:offset + 2]
        offset += 2
        if not 0 <= left < right <= n:
            return -1, b""
        queries.append((left, right))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < 8 * q:
        return -2, b""
    payload = b"".join(struct.pack("<q", answer) for answer in _mo_answers(array, queries))
    return len(payload), payload
