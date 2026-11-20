"""FIFO BFS reference over the bounded cell/budget product graph."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

ALGORITHM = "grid_shortest_path_obstacle_elimination"
MIN_DIMENSION = 1
MAX_DIMENSION = 6
MAX_BUDGET = 6
MAX_VALID_INPUT_LENGTH = 39
MAX_PARSEABLE_INPUT_LENGTH = 40
MAX_STATES = 252
MAX_WORKSPACE_BYTES = 8192
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, int, int, list[int]] | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    if input_length is not None and input_length != len(values):
        return None

    rows, columns, budget = values[:3]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION:
        return None
    if not MIN_DIMENSION <= columns <= MAX_DIMENSION or not 0 <= budget <= MAX_BUDGET:
        return None
    if len(values) != 3 + rows * columns:
        return None
    cells = list(values[3:])
    if any(cell not in (0, 1) for cell in cells):
        return None
    if cells[0] != 0 or cells[-1] != 0:
        return None
    return rows, columns, budget, cells


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -2
    rows, columns, budget, cells = parsed
    stride = budget + 1
    state_count = rows * columns * stride
    start_state = budget
    target_cell = rows * columns - 1

    distance = [-1] * state_count
    distance[start_state] = 0
    queue = deque([start_state])

    while queue:
        state = queue.popleft()
        cell, remaining = divmod(state, stride)
        if cell == target_cell:
            return distance[state]
        row, column = divmod(cell, columns)
        neighbors = (
            (row - 1, column),
            (row, column - 1),
            (row, column + 1),
            (row + 1, column),
        )
        for next_row, next_column in neighbors:
            if not 0 <= next_row < rows or not 0 <= next_column < columns:
                continue
            next_cell = next_row * columns + next_column
            next_remaining = remaining - cells[next_cell]
            if next_remaining < 0:
                continue
            next_state = next_cell * stride + next_remaining
            if distance[next_state] != -1:
                continue
            distance[next_state] = distance[state] + 1
            queue.append(next_state)
    return -1
