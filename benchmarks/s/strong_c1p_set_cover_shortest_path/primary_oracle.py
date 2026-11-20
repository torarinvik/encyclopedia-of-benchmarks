"""Schöbel's bounded shortest-path solver for strong-C1P set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 10
MAX_PARSEABLE_INPUT_LENGTH = 21
MAX_OUTPUT_BYTES = 8
MAX_WORKSPACE_BYTES = 8192


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
    masks = list(values[2 + columns:])
    if any(weight < 1 or weight > 20 for weight in weights):
        return None
    valid_mask = (1 << columns) - 1
    if any(mask < 0 or mask & ~valid_mask for mask in masks):
        return None
    for mask in masks:
        seen_one = False
        seen_zero_after = False
        for column in range(columns):
            bit_is_one = bool(mask & (1 << column))
            if bit_is_one:
                if seen_zero_after:
                    return None
                seen_one = True
            elif seen_one:
                seen_zero_after = True
    return rows, columns, weights, masks


def _strictly_monotone_rows(masks: Sequence[int], columns: int) -> list[tuple[int, int]]:
    """Apply Schöbel Algorithm 1's two interval-row reductions.

    Equal starts retain a shortest interval (duplicate intervals retain the
    earliest input row). Then only strict suffix minima of right endpoints
    survive, which is equivalent to the stated suffix-minimum deletion rule
    with its rightmost tie choice.
    """
    intervals: list[tuple[int, int, int]] = []
    for row, mask in enumerate(masks):
        if mask == 0:
            return []
        columns_in_row = [column for column in range(columns) if mask & (1 << column)]
        intervals.append((columns_in_row[0], columns_in_row[-1], row))
    intervals.sort(key=lambda item: (item[0], item[2]))

    unique_starts: list[tuple[int, int]] = []
    for start, end, _row in intervals:
        if not unique_starts or unique_starts[-1][0] != start:
            unique_starts.append((start, end))
        elif end < unique_starts[-1][1]:
            unique_starts[-1] = (start, end)

    suffix_min = columns
    retained_reverse: list[tuple[int, int]] = []
    for start, end in reversed(unique_starts):
        if end < suffix_min:
            retained_reverse.append((start, end))
            suffix_min = end
    return list(reversed(retained_reverse))


def _solve(rows: int, columns: int, weights: Sequence[int], masks: Sequence[int]) -> int:
    if any(mask == 0 for mask in masks):
        return -1
    reduced = _strictly_monotone_rows(masks, columns)
    if not reduced:
        return -1

    # In the strictly monotone row form, every nonempty column covers an
    # interval of reduced rows (Schöbel Lemma 3).
    column_start = [-1] * columns
    column_end = [-1] * columns
    for column in range(columns):
        covered_rows = [index for index, (left, right) in enumerate(reduced)
                        if left <= column <= right]
        if covered_rows:
            column_start[column] = covered_rows[0]
            column_end[column] = covered_rows[-1]

    # G1 is a DAG ordered by column index. Source arcs have cost zero; every
    # outgoing arc from column j costs weights[j], including an arc to sink.
    infinity = 1 << 60
    distance = [infinity] * columns
    for column in range(columns):
        if column_start[column] == 0:
            distance[column] = 0
    best = infinity
    for left_column in range(columns):
        if distance[left_column] == infinity:
            continue
        if column_end[left_column] == len(reduced) - 1:
            best = min(best, distance[left_column] + weights[left_column])
        for right_column in range(left_column + 1, columns):
            if (column_start[right_column] >= 0
                    and column_start[right_column] <= column_end[left_column] + 1):
                distance[right_column] = min(
                    distance[right_column], distance[left_column] + weights[left_column]
                )
    return -1 if best == infinity else best


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
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    rows, columns, weights, masks = parsed
    result = _solve(rows, columns, weights, masks)
    payload = struct.pack("<q", result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
