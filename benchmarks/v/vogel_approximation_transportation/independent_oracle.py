"""Direct candidate enumeration for the bounded Vogel-method profile."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    ALLOCATION_BASE,
    INVALID_RESULT,
    MAX_COLS,
    MAX_COST,
    MAX_MARGIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_ROWS,
)


def _valid_frame(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None) -> tuple[int, int, list[list[int]], list[int], list[int]] | None:
    if input_is_null is not False or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 5 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    for item in values:
        if type(item) is not int or item < -(1 << 63) or item >= (1 << 63):
            return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    row_count, column_count = values[:2]
    if row_count not in range(1, MAX_ROWS + 1) or column_count not in range(1, MAX_COLS + 1):
        return None
    cell_count = row_count * column_count
    if len(values) != cell_count + row_count + column_count + 2:
        return None
    start = 2
    matrix = [list(values[start + i * column_count:start + (i + 1) * column_count])
              for i in range(row_count)]
    start += cell_count
    sources = list(values[start:start + row_count])
    destinations = list(values[start + row_count:])
    if any(value not in range(MAX_COST + 1) for row in matrix for value in row):
        return None
    if any(value not in range(1, MAX_MARGIN + 1) for value in sources + destinations):
        return None
    if sum(sources) != sum(destinations):
        return None
    return row_count, column_count, matrix, sources, destinations


def _pack(entries: list[list[int]], cost: int) -> int:
    encoded = cost * ALLOCATION_BASE
    for row in range(3):
        for col in range(3):
            quantity = entries[row][col] if row < len(entries) and col < len(entries[row]) else 0
            encoded += quantity * (4 ** (3 * row + col))
    return encoded


def _by_recomputed_choices(matrix: list[list[int]], supply: list[int],
                           demand: list[int]) -> tuple[list[list[int]], int]:
    rows, cols = len(supply), len(demand)
    active_row_ids = list(range(rows))
    active_col_ids = list(range(cols))
    allocation = [[0] * cols for _ in range(rows)]
    objective = 0

    while active_row_ids:
        proposals: list[tuple[int, int, int, int, int]] = []
        # Each tuple is (-penalty, line-kind, line-id, partner-id, unit-cost).
        # Recomputing sorted active cells here is intentionally separate from
        # the primary's line-by-line incremental candidate scan.
        for kind, line_ids, partner_ids in (
            (0, active_row_ids, active_col_ids),
            (1, active_col_ids, active_row_ids),
        ):
            for line_id in line_ids:
                candidates = []
                for partner_id in partner_ids:
                    row, col = ((line_id, partner_id) if kind == 0
                                else (partner_id, line_id))
                    candidates.append((matrix[row][col], partner_id))
                ordered_costs = sorted(cost for cost, _partner in candidates)
                difference = 10 if len(ordered_costs) == 1 else ordered_costs[1] - ordered_costs[0]
                cheap_cost, partner_id = min(candidates, key=lambda item: (item[0], item[1]))
                proposals.append((-difference, kind, line_id, partner_id, cheap_cost))
        _negative_penalty, kind, line_id, partner_id, _cell_cost = min(
            proposals, key=lambda item: item[:3])
        row, col = ((line_id, partner_id) if kind == 0
                    else (partner_id, line_id))
        amount = min(supply[row], demand[col])
        allocation[row][col] += amount
        objective += amount * matrix[row][col]
        supply[row] -= amount
        demand[col] -= amount
        if supply[row] == 0:
            active_row_ids.remove(row)
        if demand[col] == 0:
            active_col_ids.remove(col)
    return allocation, objective


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    frame = _valid_frame(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    _rows, _cols, matrix, supply, demand = frame
    allocation, cost = _by_recomputed_choices(matrix, supply, demand)
    return _pack(allocation, cost)
