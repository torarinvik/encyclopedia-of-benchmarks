"""Independent oracle for the bounded NPB serial DC data-cube contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DIMS = 5
MAX_ROWS = 16
MAX_INPUT_LENGTH = 2 + MAX_ROWS * (MAX_DIMS + 1)
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return INVALID_RESULT

    dimensions, row_count = values[0], values[1]
    if not 1 <= dimensions <= MAX_DIMS or not 1 <= row_count <= MAX_ROWS:
        return INVALID_RESULT
    if actual_length != 2 + row_count * (dimensions + 1):
        return INVALID_RESULT

    rows: list[tuple[tuple[int, ...], int]] = []
    offset = 2
    for _ in range(row_count):
        attributes = tuple(values[offset:offset + dimensions])
        offset += dimensions
        measure = values[offset]
        offset += 1
        if any(not 0 <= value <= 7 for value in attributes) or not 0 <= measure <= 1000:
            return INVALID_RESULT
        rows.append((attributes, measure))

    checksum = 0
    for mask in range(1, 1 << dimensions):
        selected = tuple(dimension for dimension in range(dimensions) if mask & (1 << dimension))
        grouped: dict[tuple[int, ...], int] = {}
        for attributes, measure in rows:
            key = tuple(attributes[dimension] for dimension in selected)
            grouped[key] = grouped.get(key, 0) + measure
        ordered = sorted(grouped.items())
        checksum += mask * 1009 + len(ordered) * 9176
        for group_index, (key, measure_sum) in enumerate(ordered):
            checksum += (mask + 1) * (group_index + 1) * (measure_sum + 13)
            for position, dimension in enumerate(selected):
                checksum += (dimension + 1) * (key[position] + 1) * (group_index + 3) * (mask + 5)
    return checksum
