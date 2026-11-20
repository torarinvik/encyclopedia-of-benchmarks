"""Set-based reduction oracle with exhaustive optimum-preservation checking."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 8
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 272


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return None
    m, n = values[:2]
    if not 1 <= m <= MAX_ROWS or not 1 <= n <= MAX_COLUMNS or len(values) != 2 + n + m:
        return None
    weights = list(values[2:2 + n])
    if any(weight < 1 or weight > 20 for weight in weights):
        return None
    row_sets = []
    for mask in values[2 + n:]:
        if mask < 0 or mask >> n:
            return None
        row_sets.append({column for column in range(n) if mask & (1 << column)})
    return m, n, weights, row_sets


def _minimum_cost(rows: list[set[int]], columns: list[int], weights: dict[int, int]):
    best: int | None = None
    for selected_bits in range(1 << len(columns)):
        selected = {columns[index] for index in range(len(columns)) if selected_bits & (1 << index)}
        if not all(row & selected for row in rows):
            continue
        cost = sum(weights[column] for column in selected)
        if best is None or cost < best:
            best = cost
    return best


def _reduce(rows: list[set[int]], weights: list[int]):
    active_rows = list(range(len(rows)))
    active_columns = list(range(len(weights)))
    row_options = [set(row) for row in rows]
    column_weights = {column: weights[column] for column in active_columns}

    while True:
        changed = False
        for keep in active_rows:
            for drop in active_rows:
                if keep == drop:
                    continue
                keep_options = row_options[keep]
                drop_options = row_options[drop]
                if keep_options <= drop_options and (keep_options != drop_options or keep < drop):
                    active_rows.remove(drop)
                    changed = True
                    break
            if changed:
                break
        if changed:
            continue

        for drop in active_columns:
            drop_coverage = {row for row in active_rows if drop in row_options[row]}
            for keep in active_columns:
                if keep == drop:
                    continue
                keep_coverage = {row for row in active_rows if keep in row_options[row]}
                if (
                    drop_coverage <= keep_coverage
                    and column_weights[drop] >= column_weights[keep]
                    and (drop_coverage != keep_coverage or column_weights[drop] != column_weights[keep] or keep < drop)
                ):
                    active_columns.remove(drop)
                    for row in active_rows:
                        row_options[row].discard(drop)
                    changed = True
                    break
            if changed:
                break
        if not changed:
            for drop in active_columns:
                drop_coverage = {row for row in active_rows if drop in row_options[row]}
                for keep in active_columns:
                    if keep == drop:
                        continue
                    keep_coverage = {row for row in active_rows if keep in row_options[row]}
                    exclusive_rows = drop_coverage - keep_coverage
                    if not drop_coverage.intersection(keep_coverage) or not exclusive_rows:
                        continue
                    cheapest_by_row = {}
                    feasible = True
                    for row in exclusive_rows:
                        choices = [column for column in active_columns if column in row_options[row]]
                        if not choices:
                            feasible = False
                            break
                        cheapest_by_row[row] = min(choices, key=lambda column: (column_weights[column], column))
                    replacement_columns = set(cheapest_by_row.values())
                    replacement_cost = column_weights[keep] + sum(column_weights[column] for column in replacement_columns)
                    if feasible and column_weights[drop] >= replacement_cost:
                        active_columns.remove(drop)
                        for row in active_rows:
                            row_options[row].discard(drop)
                        changed = True
                        break
                if changed:
                    break
            if not changed:
                break

    reduced_rows = [row_options[row] for row in active_rows]
    before = _minimum_cost(rows, list(range(len(weights))), column_weights)
    after = _minimum_cost(reduced_rows, active_columns, column_weights)
    if before != after:
        raise AssertionError("row/column reductions changed the exact minimum cover cost")

    compact_column_index = {column: index for index, column in enumerate(active_columns)}
    reduced_masks = []
    for row in reduced_rows:
        mask = 0
        for column in row:
            if column in compact_column_index:
                mask |= 1 << compact_column_index[column]
        reduced_masks.append(mask)
    return active_rows, active_columns, [column_weights[column] for column in active_columns], reduced_masks


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
    decoded = _decode(framed)
    if decoded is None:
        return -1, b""
    rows, columns, weights, row_sets = decoded
    row_ids, column_ids, reduced_weights, reduced_masks = _reduce(row_sets, weights)
    words = [len(row_ids), len(column_ids), *row_ids, *column_ids, *reduced_weights, *reduced_masks]
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
