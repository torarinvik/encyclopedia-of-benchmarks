"""Primary frequency-ordered reference for Sunday Optimal Mismatch."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MIN_PATTERN_LENGTH = 1
MAX_PATTERN_LENGTH = 16
MAX_VALID_INPUT_LENGTH = 274
MAX_PARSEABLE_INPUT_LENGTH = 274
INVALID_RESULT = -2
NOT_FOUND = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Search by increasing text frequency, combining two safe shifts."""
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if length is None:
        declared = len(values) if isinstance(values, (tuple, list)) else -1
    elif type(length) is int and length >= 0:
        declared = length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or declared != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    n, m = values[0], values[1]
    if (not 0 <= n <= MAX_TEXT_LENGTH
            or not MIN_PATTERN_LENGTH <= m <= MAX_PATTERN_LENGTH
            or len(values) != 2 + n + m):
        return INVALID_RESULT
    text = values[2:2 + n]
    pattern = values[2 + n:]
    if any(byte < 0 or byte > 127 for byte in text + pattern):
        return INVALID_RESULT
    if m > n:
        return NOT_FOUND

    frequency = [0] * 128
    for byte in text:
        frequency[byte] += 1
    order = list(range(m))
    # Small m allows deterministic insertion sort without a library comparator.
    for index in range(1, m):
        selected = order[index]
        cursor = index
        while cursor > 0:
            previous = order[cursor - 1]
            if (frequency[pattern[previous]], -previous) <= (frequency[pattern[selected]], -selected):
                break
            order[cursor] = previous
            cursor -= 1
        order[cursor] = selected

    quick_shift = [m + 1] * 128
    for index, byte in enumerate(pattern):
        quick_shift[byte] = m - index

    adapted_shift = [m] * m
    for rank, mismatch_at in enumerate(order):
        for shift in range(1, m + 1):
            compatible = True
            for prior_rank in range(rank):
                position = order[prior_rank]
                if position >= shift and pattern[position] != pattern[position - shift]:
                    compatible = False
                    break
            if not compatible:
                continue
            if mismatch_at >= shift and pattern[mismatch_at - shift] == pattern[mismatch_at]:
                continue
            adapted_shift[rank] = shift
            break

    start = 0
    last_start = n - m
    while start <= last_start:
        rank = 0
        while rank < m and text[start + order[rank]] == pattern[order[rank]]:
            rank += 1
        if rank == m:
            return start
        if start + m == n:
            break
        start += max(adapted_shift[rank], quick_shift[text[start + m]])
    return NOT_FOUND
