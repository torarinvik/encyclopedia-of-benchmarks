"""Repeated edge relaxation over product states, independent of FIFO BFS."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DIMENSION = 6
MAX_BUDGET = 6
MAX_VALID_INPUT_LENGTH = 39
MAX_PARSEABLE_INPUT_LENGTH = 40
MAX_STATES = 252
MAX_WORKSPACE_BYTES = 8192
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, int, int, tuple[int, ...]] | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(item) is not int or item < I64_MIN or item > I64_MAX for item in values):
        return None
    r, c, budget = values[0], values[1], values[2]
    if not 1 <= r <= MAX_DIMENSION or not 1 <= c <= MAX_DIMENSION:
        return None
    if not 0 <= budget <= MAX_BUDGET or len(values) != 3 + r * c:
        return None
    cells = tuple(values[3:])
    if any(item not in (0, 1) for item in cells) or cells[0] != 0 or cells[-1] != 0:
        return None
    return r, c, budget, cells


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -2
    rows, columns, budget, cells = parsed
    levels = budget + 1
    state_count = rows * columns * levels
    infinity = state_count + 1
    distances = [infinity] * state_count
    distances[budget] = 0

    neighbors: list[list[int]] = [[] for _ in range(rows * columns)]
    for cell in range(rows * columns):
        row, column = divmod(cell, columns)
        if row > 0:
            neighbors[cell].append(cell - columns)
        if column > 0:
            neighbors[cell].append(cell - 1)
        if column + 1 < columns:
            neighbors[cell].append(cell + 1)
        if row + 1 < rows:
            neighbors[cell].append(cell + columns)

    for _ in range(state_count - 1):
        updated = distances.copy()
        changed = False
        for state, distance in enumerate(distances):
            if distance == infinity:
                continue
            cell, remaining = divmod(state, levels)
            for next_cell in neighbors[cell]:
                next_remaining = remaining - cells[next_cell]
                if next_remaining < 0:
                    continue
                next_state = next_cell * levels + next_remaining
                candidate = distance + 1
                if candidate < updated[next_state]:
                    updated[next_state] = candidate
                    changed = True
        distances = updated
        if not changed:
            break

    target_start = (rows * columns - 1) * levels
    answer = min(distances[target_start:target_start + levels])
    return -1 if answer == infinity else answer
