"""Primary oracle for the bounded NPB DC smallest-parent contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DIMS = 5
MAX_ROWS = 16
MAX_INPUT_LENGTH = 2 + MAX_ROWS * (MAX_DIMS + 1)
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    dimensions, row_count = values[0], values[1]
    if not 1 <= dimensions <= MAX_DIMS or not 1 <= row_count <= MAX_ROWS:
        return None
    if actual_length != 2 + row_count * (dimensions + 1):
        return None
    rows: list[tuple[tuple[int, ...], int]] = []
    offset = 2
    for _ in range(row_count):
        key = tuple(values[offset:offset + dimensions])
        offset += dimensions
        measure = values[offset]
        offset += 1
        if any(not 0 <= value <= 7 for value in key) or not 0 <= measure <= 1000:
            return None
        rows.append((key, measure))
    return dimensions, rows


def _group_projected(rows: list[tuple[tuple[int, ...], int]], mask: int, dimensions: int):
    selected = tuple(d for d in range(dimensions) if mask & (1 << d))
    totals: dict[tuple[int, ...], int] = {}
    for attributes, measure in rows:
        key = tuple(attributes[d] for d in selected)
        totals[key] = totals.get(key, 0) + measure
    return sorted(totals.items())


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    parsed = _parse(values, input_length)
    if parsed is None:
        return INVALID_RESULT
    dimensions, raw_rows = parsed
    full_mask = (1 << dimensions) - 1
    views: dict[int, list[tuple[tuple[int, ...], int]]] = {
        full_mask: _group_projected(raw_rows, full_mask, dimensions)
    }
    parents = {full_mask: -1}

    for popcount in range(dimensions - 1, -1, -1):
        for mask in range(full_mask + 1):
            if mask.bit_count() != popcount:
                continue
            candidates = [mask | (1 << d) for d in range(dimensions) if not mask & (1 << d)]
            parent = min(candidates, key=lambda candidate: (len(views[candidate]), candidate ^ mask))
            parents[mask] = parent
            selected = tuple(d for d in range(dimensions) if mask & (1 << d))
            parent_columns = tuple(d for d in range(dimensions) if parent & (1 << d))
            parent_positions = {dimension: position for position, dimension in enumerate(parent_columns)}
            totals: dict[tuple[int, ...], int] = {}
            for parent_key, measure_sum in views[parent]:
                key = tuple(parent_key[parent_positions[d]] for d in selected)
                totals[key] = totals.get(key, 0) + measure_sum
            views[mask] = sorted(totals.items())

    checksum = 0
    for mask in range(full_mask + 1):
        view = views[mask]
        parent_code = parents[mask] + 2
        checksum += (mask + 1) * 1_000_000 + parent_code * 10_000 + len(view) * 1_000
        selected = tuple(d for d in range(dimensions) if mask & (1 << d))
        for group_index, (key, measure_sum) in enumerate(view):
            rank = group_index + 1
            checksum += rank * (measure_sum + 1)
            for position, dimension in enumerate(selected):
                checksum += rank * (dimension + 1) * (key[position] + 1)
    return checksum
