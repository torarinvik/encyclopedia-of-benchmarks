"""Oracle for the bounded, sequence-producing shortest common supersequence."""
from __future__ import annotations

from collections.abc import Sequence

MIN_SEQUENCE_LENGTH = 0
MAX_SEQUENCE_LENGTH = 64
MIN_ASCII = 32
MAX_ASCII = 126
MAX_INPUT_LENGTH = 2 + 2 * MAX_SEQUENCE_LENGTH
MAX_OUTPUT_BYTES = 2 * MAX_SEQUENCE_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _valid_values(values: Sequence[int] | None) -> bool:
    return (
        isinstance(values, (list, tuple))
        and all(type(value) is int and -(1 << 63) <= value < (1 << 63) for value in values)
    )


def _build_supersequence(left: Sequence[int], right: Sequence[int]) -> bytes:
    """Match the pinned LCS backtracking rule: ties choose the right sequence."""
    m, n = len(left), len(right)
    lcs = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if left[i - 1] == right[j - 1]:
                lcs[i][j] = lcs[i - 1][j - 1] + 1
            else:
                lcs[i][j] = max(lcs[i - 1][j], lcs[i][j - 1])

    reverse_result: list[int] = []
    i, j = m, n
    while i > 0 and j > 0:
        if left[i - 1] == right[j - 1]:
            reverse_result.append(left[i - 1])
            i -= 1
            j -= 1
        elif lcs[i - 1][j] > lcs[i][j - 1]:
            reverse_result.append(left[i - 1])
            i -= 1
        else:
            reverse_result.append(right[j - 1])
            j -= 1
    while i > 0:
        reverse_result.append(left[i - 1])
        i -= 1
    while j > 0:
        reverse_result.append(right[j - 1])
        j -= 1
    return bytes(reversed(reverse_result))


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI result and output bytes for one packed input."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or not _valid_values(values):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""

    m, n = values[0], values[1]
    if not MIN_SEQUENCE_LENGTH <= m <= MAX_SEQUENCE_LENGTH:
        return INVALID_RESULT, b""
    if not MIN_SEQUENCE_LENGTH <= n <= MAX_SEQUENCE_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != 2 + m + n:
        return INVALID_RESULT, b""
    left = values[2:2 + m]
    right = values[2 + m:]
    if any(not MIN_ASCII <= value <= MAX_ASCII for value in (*left, *right)):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    result = _build_supersequence(left, right)
    if output_is_null or (capacity is not None and capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
