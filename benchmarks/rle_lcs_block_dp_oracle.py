"""Primary oracle for run-length-native block dynamic programming for LCS."""

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
    if not 1 <= left_count <= MAX_RUNS:
        return None
    right_count_index = 1 + 2 * left_count
    if right_count_index >= len(values):
        return None
    right_count = values[right_count_index]
    if not 1 <= right_count <= MAX_RUNS or len(values) != right_count_index + 1 + 2 * right_count:
        return None

    def read_runs(start: int, count: int):
        runs = []
        expanded = 0
        for run in range(count):
            symbol, run_length = values[start + 2 * run:start + 2 * run + 2]
            if not 0 <= symbol <= 3 or not 1 <= run_length <= 8:
                return None
            expanded += run_length
            if expanded > MAX_EXPANDED_LENGTH:
                return None
            runs.append((symbol, run_length))
        return runs

    left = read_runs(1, left_count)
    right = read_runs(right_count_index + 1, right_count)
    if left is None or right is None:
        return None
    return left, right


def _block_lcs(left: list[tuple[int, int]], right: list[tuple[int, int]]) -> int:
    # bottom[j] is the lower boundary of the previous left-run block row.
    bottom = [[0] * (right[j][1] + 1) for j in range(len(right))]
    next_bottom = [[0] * (right[j][1] + 1) for j in range(len(right))]
    for left_symbol, left_length in left:
        left_boundary = [0] * (left_length + 1)
        for block, (right_symbol, right_length) in enumerate(right):
            previous = bottom[block].copy()
            right_boundary = [0] * (left_length + 1)
            right_boundary[0] = previous[right_length]
            for row in range(1, left_length + 1):
                current = [0] * (right_length + 1)
                current[0] = left_boundary[row]
                for column in range(1, right_length + 1):
                    if left_symbol == right_symbol:
                        current[column] = previous[column - 1] + 1
                    else:
                        current[column] = max(previous[column], current[column - 1])
                right_boundary[row] = current[right_length]
                previous = current
            next_bottom[block] = previous.copy()
            left_boundary = right_boundary
        bottom, next_bottom = next_bottom, bottom
    return bottom[-1][-1]


def expected_result(values: Sequence[int] | None) -> int:
    decoded = _decode(values)
    if decoded is None:
        return -1
    left, right = decoded
    return _block_lcs(left, right)
