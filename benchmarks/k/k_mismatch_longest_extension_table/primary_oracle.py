"""Suffix-array/LCP-RMQ oracle for the bounded longest-extension table."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_K = 4
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_OUTPUT_BYTES = 320
WORKSPACE_BYTES = 8192


def _suffix_array(text: list[int]) -> list[int]:
    n = len(text)
    order = list(range(n))
    rank = text[:]
    width = 1
    while width < n:
        def less(a: int, b: int) -> bool:
            first_a, first_b = rank[a], rank[b]
            if first_a != first_b:
                return first_a < first_b
            second_a = rank[a + width] if a + width < n else -1
            second_b = rank[b + width] if b + width < n else -1
            return second_a < second_b

        for i in range(1, n):
            key = order[i]
            j = i
            while j and less(key, order[j - 1]):
                order[j] = order[j - 1]
                j -= 1
            order[j] = key

        new_rank = [0] * n
        classes = 0
        for i in range(1, n):
            a, b = order[i - 1], order[i]
            pair_a = (rank[a], rank[a + width] if a + width < n else -1)
            pair_b = (rank[b], rank[b + width] if b + width < n else -1)
            if pair_a != pair_b:
                classes += 1
            new_rank[b] = classes
        rank = new_rank
        if classes == n - 1:
            break
        width *= 2
    return order


def _lce_index(text: list[int], suffixes: list[int]):
    n = len(text)
    inverse = [0] * n
    for rank, start in enumerate(suffixes):
        inverse[start] = rank
    lcp = [0] * n
    matched = 0
    for start in range(n):
        rank = inverse[start]
        if rank == 0:
            matched = 0
            continue
        other = suffixes[rank - 1]
        while start + matched < n and other + matched < n and text[start + matched] == text[other + matched]:
            matched += 1
        lcp[rank] = matched
        if matched:
            matched -= 1

    levels = max(1, n.bit_length())
    sparse = [lcp]
    for level in range(1, levels):
        span = 1 << level
        half = span >> 1
        previous = sparse[-1]
        row = [0] * n
        for left in range(n - span + 1):
            row[left] = min(previous[left], previous[left + half])
        sparse.append(row)
    logs = [0] * (n + 1)
    for length in range(2, n + 1):
        logs[length] = logs[length // 2] + 1

    def lce(left: int, right: int) -> int:
        if left >= n or right >= n:
            return 0
        if left == right:
            return n - left
        a, b = inverse[left], inverse[right]
        if a > b:
            a, b = b, a
        lo = a + 1
        length = b - a
        level = logs[length]
        span = 1 << level
        return min(sparse[level][lo], sparse[level][b - span + 1])

    return lce


def _parse(values: Sequence[int] | None, input_length: int | None) -> tuple[list[int], int] | None:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n, budget = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= budget <= MAX_K or declared != n + 2:
        return None
    text = list(values[2:])
    if any(symbol < 0 or symbol > 25 for symbol in text):
        return None
    return text, budget


def _table(text: list[int], budget: int) -> bytes:
    suffixes = _suffix_array(text)
    lce = _lce_index(text, suffixes)
    n = len(text)
    output = bytearray()
    for p in range(n):
        limit = n - p
        extension = lce(0, p)
        output.append(min(extension, limit))
        for _ in range(budget):
            if extension < limit:
                extension = min(limit, extension + 1 + lce(extension + 1, p + extension + 1))
            output.append(extension)
    return bytes(output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    text, budget = parsed
    payload = _table(text, budget)
    if len(payload) > MAX_OUTPUT_BYTES:
        return -1, b""
    if payload and (output_is_null or (capacity is not None and capacity < len(payload))):
        return -2, b""
    return len(payload), payload
