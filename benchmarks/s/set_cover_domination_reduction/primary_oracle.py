"""Bit-mask reference for DOI 368 row/column set-cover reductions."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 8
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 272


def _parse(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    row_count, column_count = values[:2]
    if not 1 <= row_count <= MAX_ROWS or not 1 <= column_count <= MAX_COLUMNS:
        return None
    if len(values) != 2 + column_count + row_count:
        return None
    weights = list(values[2:2 + column_count])
    if any(not 1 <= weight <= 20 for weight in weights):
        return None
    valid_columns = (1 << column_count) - 1
    row_masks = list(values[2 + column_count:])
    if any(mask < 0 or mask & ~valid_columns for mask in row_masks):
        return None
    return row_count, column_count, weights, row_masks


def _reduce(rows: int, columns: int, weights: list[int], masks: list[int]):
    active_rows = [True] * rows
    active_columns = [True] * columns
    while True:
        changed = False
        for keep in range(rows):
            if not active_rows[keep]:
                continue
            for drop in range(rows):
                if not active_rows[drop] or keep == drop:
                    continue
                keep_mask = masks[keep]
                drop_mask = masks[drop]
                if keep_mask & ~drop_mask == 0 and (keep_mask != drop_mask or keep < drop):
                    active_rows[drop] = False
                    changed = True
                    break
            if changed:
                break
        if changed:
            continue

        for drop in range(columns):
            if not active_columns[drop]:
                continue
            drop_coverage = 0
            for row in range(rows):
                if active_rows[row] and masks[row] & (1 << drop):
                    drop_coverage |= 1 << row
            for keep in range(columns):
                if not active_columns[keep] or keep == drop:
                    continue
                keep_coverage = 0
                for row in range(rows):
                    if active_rows[row] and masks[row] & (1 << keep):
                        keep_coverage |= 1 << row
                if (
                    drop_coverage & ~keep_coverage == 0
                    and weights[drop] >= weights[keep]
                    and (drop_coverage != keep_coverage or weights[drop] != weights[keep] or keep < drop)
                ):
                    active_columns[drop] = False
                    for row in range(rows):
                        masks[row] &= ~(1 << drop)
                    changed = True
                    break
            if changed:
                break
        if not changed:
            for drop in range(columns):
                if not active_columns[drop]:
                    continue
                drop_coverage = 0
                for row in range(rows):
                    if active_rows[row] and masks[row] & (1 << drop):
                        drop_coverage |= 1 << row
                for keep in range(columns):
                    if not active_columns[keep] or keep == drop:
                        continue
                    keep_coverage = 0
                    for row in range(rows):
                        if active_rows[row] and masks[row] & (1 << keep):
                            keep_coverage |= 1 << row
                    exclusive_rows = drop_coverage & ~keep_coverage
                    if drop_coverage & keep_coverage == 0 or exclusive_rows == 0:
                        continue
                    replacement_columns = 0
                    feasible = True
                    for row in range(rows):
                        if not exclusive_rows & (1 << row):
                            continue
                        minimum_column = -1
                        for candidate in range(columns):
                            if not active_columns[candidate] or not masks[row] & (1 << candidate):
                                continue
                            if minimum_column < 0 or (weights[candidate], candidate) < (weights[minimum_column], minimum_column):
                                minimum_column = candidate
                        if minimum_column < 0:
                            feasible = False
                            break
                        replacement_columns |= 1 << minimum_column
                    replacement_cost = weights[keep]
                    for candidate in range(columns):
                        if replacement_columns & (1 << candidate):
                            replacement_cost += weights[candidate]
                    if feasible and weights[drop] >= replacement_cost:
                        active_columns[drop] = False
                        for row in range(rows):
                            masks[row] &= ~(1 << drop)
                        changed = True
                        break
                if changed:
                    break
            if not changed:
                break
    row_ids = [row for row in range(rows) if active_rows[row]]
    column_ids = [column for column in range(columns) if active_columns[column]]
    reduced_masks: list[int] = []
    for row in row_ids:
        mask = 0
        for compact_column, original_column in enumerate(column_ids):
            if masks[row] & (1 << original_column):
                mask |= 1 << compact_column
        reduced_masks.append(mask)
    return row_ids, column_ids, [weights[column] for column in column_ids], reduced_masks


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null and values is not None and input_length is not None
        and (not isinstance(values, (list, tuple)) or input_length != len(values))
    ):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if not isinstance(values, (list, tuple)):
        return -1, b""
    framed = values if input_length is None else values[:input_length]
    parsed = _parse(framed)
    if parsed is None:
        return -1, b""
    rows, columns, weights, masks = parsed
    row_ids, column_ids, reduced_weights, reduced_masks = _reduce(rows, columns, weights, masks)
    words = [len(row_ids), len(column_ids), *row_ids, *column_ids, *reduced_weights, *reduced_masks]
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
