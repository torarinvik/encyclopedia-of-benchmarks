"""Bounded exact oracle for DOI 368's row-wise feasible-cover enumeration."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 10
MAX_INPUT_LENGTH = 21
MAX_OUTPUT_BYTES = 80
MAX_WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows + columns:
        return None
    weights = values[2:2 + columns]
    if any(weight < 1 or weight > 20 for weight in weights):
        return None
    valid_mask = (1 << columns) - 1
    row_masks = values[2 + columns:]
    if any(mask < 0 or mask & ~valid_mask for mask in row_masks):
        return None
    return rows, columns, list(weights), list(row_masks)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    rows, columns, weights, row_masks = parsed
    state_count = 1 << columns
    feasible = [False] * state_count
    feasible[0] = True
    for row in range(rows):
        cover = row_masks[row]
        for selected in range(state_count):
            if not feasible[selected] or selected & cover:
                continue
            feasible[selected] = False
            for column in range(columns):
                bit = 1 << column
                if cover & bit:
                    feasible[selected | bit] = True

    candidates = []
    for mask, is_feasible in enumerate(feasible):
        if is_feasible:
            cost = sum(weights[column] for column in range(columns) if mask & (1 << column))
            candidates.append((cost, mask))
    if not candidates:
        payload = struct.pack("<q", -1)
    else:
        cost, mask = min(candidates)
        selected_columns = [column for column in range(columns) if mask & (1 << column)]
        payload_values = [len(selected_columns), *selected_columns, cost]
        payload = struct.pack("<" + "q" * len(payload_values), *payload_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
