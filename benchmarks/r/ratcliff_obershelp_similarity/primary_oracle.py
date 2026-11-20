"""Dynamic-programming reference for bounded Ratcliff/Obershelp similarity."""

from __future__ import annotations

MAX_TEXT = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_TEXT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
WORKSPACE_BYTES = 16384


def _longest_match(
    first: tuple[int, ...], second: tuple[int, ...],
    first_start: int, first_end: int, second_start: int, second_end: int,
) -> tuple[int, int, int]:
    """Return length and leftmost pair of starts for a longest common block."""
    width = second_end - second_start
    dp = [0] * (width + 1)
    best_length = 0
    best_first = 0
    best_second = 0
    for i in range(first_start, first_end):
        diagonal = 0
        for column in range(1, width + 1):
            old = dp[column]
            j = second_start + column - 1
            if first[i] == second[j]:
                current = diagonal + 1
                dp[column] = current
                if current > best_length:
                    best_length = current
                    best_first = i - current + 1
                    best_second = j - current + 1
            else:
                dp[column] = 0
            diagonal = old
    return best_length, best_first, best_second


def _matched_characters(first: tuple[int, ...], second: tuple[int, ...]) -> int:
    """Recursively split around the leftmost longest common substring."""
    def visit(a0: int, a1: int, b0: int, b1: int) -> int:
        length, a, b = _longest_match(first, second, a0, a1, b0, b1)
        if length == 0:
            return 0
        return (length + visit(a0, a, b0, b)
                + visit(a + length, a1, b + length, b1))

    return visit(0, len(first), 0, len(second))


def expected_result(
    values: list[int] | tuple[int, ...], *,
    input_length: int | None = None, input_is_null: bool = False,
) -> int:
    """Return the floor percentage, or -1 for an invalid ABI frame."""
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
    first_length, second_length = values[0], values[1]
    if not (0 <= first_length <= MAX_TEXT and 0 <= second_length <= MAX_TEXT):
        return -1
    if input_length != 2 + first_length + second_length:
        return -1
    first = tuple(values[2:2 + first_length])
    second = tuple(values[2 + first_length:])
    if any(not 1 <= byte <= 127 for byte in (*first, *second)):
        return -1
    if first_length == 0 or second_length == 0:
        return 0
    common = _matched_characters(first, second)
    return (200 * common) // (first_length + second_length)
