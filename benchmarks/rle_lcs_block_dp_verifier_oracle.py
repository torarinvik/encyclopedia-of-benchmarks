"""Independent full-table LCS verifier reading symbols from RLE runs on demand."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RUNS = 4
MAX_EXPANDED_LENGTH = 16
MAX_INPUT_LENGTH = 18


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    left_count = values[0]
    if left_count < 1 or left_count > MAX_RUNS:
        return None
    right_count_index = 1 + 2 * left_count
    if right_count_index >= len(values):
        return None
    right_count = values[right_count_index]
    if right_count < 1 or right_count > MAX_RUNS or len(values) != right_count_index + 1 + 2 * right_count:
        return None

    def read_runs(start: int, count: int):
        runs = []
        length = 0
        for index in range(count):
            symbol = values[start + 2 * index]
            run_length = values[start + 2 * index + 1]
            if symbol < 0 or symbol > 3 or run_length < 1 or run_length > 8:
                return None
            length += run_length
            if length > MAX_EXPANDED_LENGTH:
                return None
            runs.append((symbol, run_length))
        return runs

    left = read_runs(1, left_count)
    right = read_runs(right_count_index + 1, right_count)
    if left is None or right is None:
        return None
    return left, right


def _symbol_at(runs: list[tuple[int, int]], position: int) -> int:
    for symbol, run_length in runs:
        if position < run_length:
            return symbol
        position -= run_length
    raise IndexError("position outside encoded sequence")


def expected_result(values: Sequence[int] | None) -> int:
    decoded = _decode(values)
    if decoded is None:
        return -1
    left, right = decoded
    left_length = sum(length for _, length in left)
    right_length = sum(length for _, length in right)
    table = [[0] * (right_length + 1) for _ in range(left_length + 1)]
    for i in range(1, left_length + 1):
        left_symbol = _symbol_at(left, i - 1)
        for j in range(1, right_length + 1):
            if left_symbol == _symbol_at(right, j - 1):
                table[i][j] = table[i - 1][j - 1] + 1
            else:
                table[i][j] = max(table[i - 1][j], table[i][j - 1])
    return table[left_length][right_length]
