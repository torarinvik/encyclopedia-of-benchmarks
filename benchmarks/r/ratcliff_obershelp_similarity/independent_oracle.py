"""Direct-substring/explicit-stack reference for Gestalt similarity."""

from __future__ import annotations

MAX_TEXT = 32
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * MAX_TEXT + 1


def _longest_direct(
    first: tuple[int, ...], second: tuple[int, ...],
    a0: int, a1: int, b0: int, b1: int,
) -> tuple[int, int, int]:
    best_length = 0
    best_a = 0
    best_b = 0
    for a in range(a0, a1):
        for b in range(b0, b1):
            length = 0
            while (a + length < a1 and b + length < b1
                   and first[a + length] == second[b + length]):
                length += 1
            if length > best_length:
                best_length, best_a, best_b = length, a, b
    return best_length, best_a, best_b


def _matched_characters(first: tuple[int, ...], second: tuple[int, ...]) -> int:
    pending = [(0, len(first), 0, len(second))]
    total = 0
    while pending:
        a0, a1, b0, b1 = pending.pop()
        length, a, b = _longest_direct(first, second, a0, a1, b0, b1)
        if length == 0:
            continue
        total += length
        # Push left first so the explicit stack visits right first; the total
        # is order-independent, and each range pair is consumed at most once.
        if a + length < a1 and b + length < b1:
            pending.append((a + length, a1, b + length, b1))
        if a0 < a and b0 < b:
            pending.append((a0, a, b0, b))
    return total


def expected_result(
    values: list[int] | tuple[int, ...], *,
    input_length: int | None = None, input_is_null: bool = False,
) -> int:
    """Return the integer percent similarity, or -1 for malformed framing."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return -1
    if input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if any(type(value) is not int for value in values):
        return -1
    n, m = values[0], values[1]
    if not (0 <= n <= MAX_TEXT and 0 <= m <= MAX_TEXT):
        return -1
    if input_length != 2 + n + m:
        return -1
    first = tuple(values[2:2 + n])
    second = tuple(values[2 + n:])
    if any(byte < 1 or byte > 127 for byte in first + second):
        return -1
    if n == 0 or m == 0:
        return 0
    return (200 * _matched_characters(first, second)) // (n + m)
