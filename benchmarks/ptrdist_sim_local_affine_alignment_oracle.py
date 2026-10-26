"""Independent bounded oracle for SIM's first-best local affine alignment."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEQUENCE_LENGTH = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_SEQUENCE_LENGTH
INVALID_RESULT = -1
MATCH_SCORE = 10
MISMATCH_SCORE = -10
GAP_OPEN = 60
GAP_EXTEND = 2
DNA = frozenset((65, 67, 71, 84))  # A, C, G, T


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return INVALID_RESULT
    left_length = values[0]
    if not 1 <= left_length <= MAX_SEQUENCE_LENGTH or 1 + left_length >= actual_length:
        return INVALID_RESULT
    right_length_offset = 1 + left_length
    right_length = values[right_length_offset]
    if not 1 <= right_length <= MAX_SEQUENCE_LENGTH:
        return INVALID_RESULT
    if actual_length != right_length_offset + 1 + right_length:
        return INVALID_RESULT
    left = values[1:right_length_offset]
    right = values[right_length_offset + 1:]
    if any(symbol not in DNA for symbol in (*left, *right)):
        return INVALID_RESULT

    rows = left_length + 1
    cols = right_length + 1
    h = [[0] * cols for _ in range(rows)]
    deletion = [[-GAP_OPEN] * cols for _ in range(rows)]
    insertion = [[-GAP_OPEN] * cols for _ in range(rows)]
    best = 0
    opening = GAP_OPEN + GAP_EXTEND
    for i in range(1, rows):
        for j in range(1, cols):
            deletion[i][j] = max(deletion[i - 1][j] - GAP_EXTEND,
                                 h[i - 1][j] - opening)
            insertion[i][j] = max(insertion[i][j - 1] - GAP_EXTEND,
                                  h[i][j - 1] - opening)
            diagonal = h[i - 1][j - 1] + (MATCH_SCORE if left[i - 1] == right[j - 1]
                                         else MISMATCH_SCORE)
            h[i][j] = max(0, diagonal, deletion[i][j], insertion[i][j])
            best = max(best, h[i][j])
    return best
