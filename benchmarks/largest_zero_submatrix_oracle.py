"""Row-wise nearest-blocker and monotone-stack oracle for a zero submatrix."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[int, int, list[list[int]]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 2 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if input_length != 2 + rows * columns:
        return None
    flat = values[2:]
    if any(cell not in (0, 1) for cell in flat):
        return None
    matrix = [list(flat[row * columns:(row + 1) * columns]) for row in range(rows)]
    return rows, columns, matrix


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    rows, columns, matrix = parsed
    last_one = [-1] * columns
    best = 0
    for row in range(rows):
        for column in range(columns):
            if matrix[row][column] == 1:
                last_one[column] = row

        left = [-1] * columns
        stack: list[int] = []
        for column in range(columns):
            while stack and last_one[stack[-1]] <= last_one[column]:
                stack.pop()
            left[column] = stack[-1] if stack else -1
            stack.append(column)

        right = [columns] * columns
        stack.clear()
        for column in range(columns - 1, -1, -1):
            while stack and last_one[stack[-1]] <= last_one[column]:
                stack.pop()
            right[column] = stack[-1] if stack else columns
            stack.append(column)

        for column in range(columns):
            height = row - last_one[column]
            width = right[column] - left[column] - 1
            best = max(best, height * width)
    return best
