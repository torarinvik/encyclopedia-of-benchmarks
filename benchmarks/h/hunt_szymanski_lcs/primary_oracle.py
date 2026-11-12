"""Bounded Hunt–Szymanski matching-pair/LIS oracle for the LCS length."""

from __future__ import annotations

MAX_SEQUENCE_LENGTH = 64
MAX_SYMBOL = 127
MAX_INPUT_LENGTH = 2 + 2 * MAX_SEQUENCE_LENGTH


def parse(values: object) -> tuple[list[int], list[int]] | None:
    if not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    n, m = values[0], values[1]
    if (not isinstance(n, int) or isinstance(n, bool)
            or not isinstance(m, int) or isinstance(m, bool)
            or not 0 <= n <= MAX_SEQUENCE_LENGTH
            or not 0 <= m <= MAX_SEQUENCE_LENGTH
            or len(values) != 2 + n + m):
        return None
    symbols = values[2:]
    if any(not isinstance(value, int) or isinstance(value, bool)
           or not 0 <= value <= MAX_SYMBOL for value in symbols):
        return None
    return symbols[:n], symbols[n:]


def expected_result(values: object) -> int:
    parsed = parse(values)
    if parsed is None:
        return -1
    left, right = parsed
    positions: list[list[int]] = [[] for _ in range(MAX_SYMBOL + 1)]
    for index, symbol in enumerate(right):
        positions[symbol].append(index)

    tails: list[int] = []
    for symbol in left:
        for position in reversed(positions[symbol]):
            low, high = 0, len(tails)
            while low < high:
                middle = (low + high) // 2
                if tails[middle] >= position:
                    high = middle
                else:
                    low = middle + 1
            if low == len(tails):
                tails.append(position)
            else:
                tails[low] = position
    return len(tails)
