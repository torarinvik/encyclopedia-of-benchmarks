"""Freivalds' matrix-product verification trace with supplied sign vectors."""
from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_ROUNDS = 8
MAX_ENTRY = 3
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_N * MAX_N + MAX_ROUNDS * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, rounds = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= rounds <= MAX_ROUNDS:
        return None
    matrix_words = n * n
    expected_length = 2 + 3 * matrix_words + rounds * n
    if len(values) != expected_length:
        return None
    offset = 2
    matrices: list[list[list[int]]] = []
    for _ in range(3):
        matrix = []
        for _row in range(n):
            row = list(values[offset:offset + n])
            if any(not -MAX_ENTRY <= entry <= MAX_ENTRY for entry in row):
                return None
            matrix.append(row)
            offset += n
        matrices.append(matrix)
    signs = []
    for _ in range(rounds):
        vector = list(values[offset:offset + n])
        if any(sign not in (-1, 1) for sign in vector):
            return None
        signs.append(vector)
        offset += n
    return n, rounds, *matrices, signs


def _verify_trace(n: int, rounds: int, a: list[list[int]], b: list[list[int]],
                  c: list[list[int]], signs: list[list[int]]) -> int:
    for round_id in range(rounds):
        vector = signs[round_id]
        bx = [sum(b[row][col] * vector[col] for col in range(n)) for row in range(n)]
        abx = [sum(a[row][col] * bx[col] for col in range(n)) for row in range(n)]
        cx = [sum(c[row][col] * vector[col] for col in range(n)) for row in range(n)]
        if abx != cx:
            return 0
    return 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    return _verify_trace(*parsed)
