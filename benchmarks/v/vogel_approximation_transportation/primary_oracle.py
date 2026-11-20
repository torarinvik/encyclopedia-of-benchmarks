"""Penalty-scan VAM reference for tiny balanced transportation tables."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 3
MAX_COLS = 3
MAX_COST = 9
MAX_MARGIN = 3
MAX_VALID_INPUT_LENGTH = 17
MAX_PARSEABLE_INPUT_LENGTH = 18
MAX_RESULT = 21_495_807
INVALID_RESULT = -1
ALLOCATION_BASE = 4 ** 9


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int], list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    rows, cols = values[0], values[1]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS:
        return None
    expected_length = 2 + rows * cols + rows + cols
    if len(values) != expected_length:
        return None
    edge = 2
    costs = list(values[edge:edge + rows * cols])
    edge += rows * cols
    supply = list(values[edge:edge + rows])
    edge += rows
    demand = list(values[edge:edge + cols])
    if any(cost < 0 or cost > MAX_COST for cost in costs):
        return None
    if any(amount < 1 or amount > MAX_MARGIN for amount in supply + demand):
        return None
    if sum(supply) != sum(demand):
        return None
    return rows, cols, costs, supply, demand


def _construct(rows: int, cols: int, costs: list[int], supply: list[int],
               demand: list[int]) -> tuple[list[int], int]:
    remaining_supply = supply.copy()
    remaining_demand = demand.copy()
    active_rows = [True] * rows
    active_cols = [True] * cols
    allocation = [0] * 9
    total_cost = 0
    remaining = sum(supply)

    while remaining > 0:
        best_penalty = -1
        best_is_row = True
        best_line = -1
        # Candidate scan order is rows first, then columns; strict replacement
        # means ties preserve the earliest line.
        for is_row in (True, False):
            line_count = rows if is_row else cols
            for line in range(line_count):
                if not (active_rows[line] if is_row else active_cols[line]):
                    continue
                partner_count = cols if is_row else rows
                line_costs: list[int] = []
                for partner in range(partner_count):
                    partner_active = active_cols[partner] if is_row else active_rows[partner]
                    if partner_active:
                        row, col = (line, partner) if is_row else (partner, line)
                        line_costs.append(costs[row * cols + col])
                if not line_costs:
                    continue
                ordered = sorted(line_costs)
                penalty = 10 if len(ordered) == 1 else ordered[1] - ordered[0]
                if penalty > best_penalty:
                    best_penalty = penalty
                    best_is_row = is_row
                    best_line = line

        partner_count = cols if best_is_row else rows
        best_partner = -1
        best_cell_cost = MAX_COST + 1
        for partner in range(partner_count):
            partner_active = active_cols[partner] if best_is_row else active_rows[partner]
            if not partner_active:
                continue
            row, col = ((best_line, partner) if best_is_row
                        else (partner, best_line))
            cell_cost = costs[row * cols + col]
            if cell_cost < best_cell_cost:
                best_cell_cost = cell_cost
                best_partner = partner

        row, col = ((best_line, best_partner) if best_is_row
                    else (best_partner, best_line))
        quantity = min(remaining_supply[row], remaining_demand[col])
        allocation[row * 3 + col] = quantity
        total_cost += quantity * costs[row * cols + col]
        remaining_supply[row] -= quantity
        remaining_demand[col] -= quantity
        remaining -= quantity
        if remaining_supply[row] == 0:
            active_rows[row] = False
        if remaining_demand[col] == 0:
            active_cols[col] = False
    return allocation, total_cost


def _encode(allocation: Sequence[int], total_cost: int) -> int:
    signature = 0
    place = 1
    for quantity in allocation:
        signature += quantity * place
        place *= 4
    return total_cost * ALLOCATION_BASE + signature


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return VAM cost/matrix encoding, or -1 for invalid input."""
    frame = _parse(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    rows, cols, costs, supply, demand = frame
    allocation, total_cost = _construct(rows, cols, costs, supply, demand)
    return _encode(allocation, total_cost)
