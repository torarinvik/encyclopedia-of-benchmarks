"""Bounded Ruf–Schöbel-style branch-and-bound set-cover reference.

The primary uses the paper's interval-block branching and solves every C1P
subproblem exactly with a shortest-path DP over column positions. It omits the
paper's optional dominance preprocessing and dual-simplex pivot strengthening.
"""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 6
MAX_COLUMNS = 8
MAX_PARSEABLE_INPUT_LENGTH = 17
MAX_OUTPUT_BYTES = 8
MAX_WORKSPACE_BYTES = 16384
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows + columns:
        return None
    weights = list(values[2:2 + columns])
    row_masks = list(values[2 + columns:])
    if any(weight < 1 or weight > 20 for weight in weights):
        return None
    valid_columns = (1 << columns) - 1
    if any(mask < 0 or mask & ~valid_columns for mask in row_masks):
        return None
    return rows, columns, weights, row_masks


def _blocks(mask: int, columns: int) -> list[tuple[int, int]]:
    """Return inclusive endpoints of the maximal 1-blocks, left to right."""
    result: list[tuple[int, int]] = []
    position = 0
    while position < columns:
        if not mask & (1 << position):
            position += 1
            continue
        left = position
        while position + 1 < columns and mask & (1 << (position + 1)):
            position += 1
        result.append((left, position))
        position += 1
    return result


def _interval_cover(intervals: Sequence[tuple[int, int]], weights: Sequence[int],
                    columns: int) -> tuple[int, int] | None:
    """Minimum-weight set of column positions hitting every closed interval.

    A path's vertices are selected column positions in increasing order. An
    edge skips a gap only when no required interval lies wholly inside it.
    Positive weights make an optimal cover a simple path. Mask ties prefer the
    numerically smaller mask for deterministic reference behavior.
    """
    if not intervals:
        return 0, 0
    minimum_right = min(right for _, right in intervals)
    maximum_left = max(left for left, _ in intervals)
    infinity = 1 << 60
    costs = [infinity] * columns
    masks = [0] * columns
    for point in range(columns):
        if point <= minimum_right:
            costs[point] = weights[point]
            masks[point] = 1 << point
        for previous in range(point):
            if costs[previous] == infinity:
                continue
            if any(previous < left and right < point for left, right in intervals):
                continue
            candidate_cost = costs[previous] + weights[point]
            candidate_mask = masks[previous] | (1 << point)
            if (candidate_cost < costs[point]
                    or candidate_cost == costs[point] and candidate_mask < masks[point]):
                costs[point] = candidate_cost
                masks[point] = candidate_mask
    best: tuple[int, int] | None = None
    for point in range(maximum_left, columns):
        if costs[point] == infinity:
            continue
        candidate = (costs[point], masks[point])
        if best is None or candidate < best:
            best = candidate
    return best


def _mask_cost(mask: int, weights: Sequence[int]) -> int:
    return sum(weight for column, weight in enumerate(weights) if mask & (1 << column))


def _solve(rows: int, columns: int, weights: Sequence[int], row_masks: Sequence[int]) -> int:
    if any(mask == 0 for mask in row_masks):
        return -1
    row_blocks = [_blocks(mask, columns) for mask in row_masks]
    # fixed[row] is -1 for an unassigned multi-block row, otherwise its block.
    fixed = [-1] * rows
    best_cost = 1 << 60
    stack = [fixed.copy()]
    while stack:
        fixed = stack.pop()
        constrained: list[tuple[int, int]] = []
        for row in range(rows):
            if len(row_blocks[row]) == 1:
                constrained.append(row_blocks[row][0])
            elif fixed[row] >= 0:
                constrained.append(row_blocks[row][fixed[row]])

        lower = _interval_cover(constrained, weights, columns)
        if lower is None:
            continue
        lower_cost, lower_mask = lower

        # Algorithm 2's cost heuristic chooses the cheapest block for every
        # original row missed by the relaxed interval cover, then augments it.
        extra_intervals: list[tuple[int, int]] = []
        for row in range(rows):
            if row_masks[row] & lower_mask:
                continue
            chosen_block = min(
                range(len(row_blocks[row])),
                key=lambda block: (
                    min(weights[column]
                        for column in range(row_blocks[row][block][0],
                                            row_blocks[row][block][1] + 1)),
                    block,
                ),
            )
            extra_intervals.append(row_blocks[row][chosen_block])
        extra = _interval_cover(extra_intervals, weights, columns)
        if extra is None:
            continue
        candidate_mask = lower_mask | extra[1]
        candidate_cost = _mask_cost(candidate_mask, weights)
        if candidate_cost < best_cost:
            best_cost = candidate_cost

        # ε=0 gives exact search: a node is expanded precisely while the
        # incumbent is strictly above its admissible C1P relaxation bound.
        if best_cost <= lower_cost:
            continue
        branch_row = next((row for row in range(rows)
                           if len(row_blocks[row]) > 1 and fixed[row] < 0), None)
        if branch_row is None:
            continue
        # Reverse push order makes the leftmost block the next state popped.
        for block in range(len(row_blocks[branch_row]) - 1, -1, -1):
            child = fixed.copy()
            child[branch_row] = block
            stack.append(child)
    return -1 if best_cost == 1 << 60 else best_cost


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    rows, columns, weights, row_masks = parsed
    optimum = _solve(rows, columns, weights, row_masks)
    payload = struct.pack("<q", optimum)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
