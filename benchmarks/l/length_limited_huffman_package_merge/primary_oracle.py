"""Bounded package-merge reference for optimal length-limited Huffman cost."""

from __future__ import annotations

from collections.abc import Sequence

MIN_SYMBOLS = 2
MAX_SYMBOLS = 12
MIN_LENGTH_LIMIT = 1
MAX_LENGTH_LIMIT = 6
MIN_WEIGHT = 0
MAX_WEIGHT = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_SYMBOLS + 2
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_SYMBOLS * MAX_LENGTH_LIMIT * MAX_WEIGHT


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not MIN_SYMBOLS + 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    symbol_count, length_limit = values[:2]
    if (not MIN_SYMBOLS <= symbol_count <= MAX_SYMBOLS
            or not MIN_LENGTH_LIMIT <= length_limit <= MAX_LENGTH_LIMIT
            or symbol_count > 1 << length_limit
            or len(values) != symbol_count + 2
            or any(not MIN_WEIGHT <= weight <= MAX_WEIGHT for weight in values[2:])):
        return None
    return symbol_count, length_limit, list(values[2:])


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    symbol_count, length_limit, weights = parsed
    levels = [sorted(weights) for _ in range(length_limit)]
    remaining_width = (symbol_count - 1) << length_limit
    total_weight = 0
    level = 0

    # Widths are scaled by 2**L, so the node width at code depth d is
    # 2**(L-d). Package-merge solves the resulting power-of-two coin problem.
    while remaining_width > 0:
        while level < len(levels) and not levels[level]:
            level += 1
        if level >= len(levels):
            return -1
        width = 1 << level
        smallest_needed_width = remaining_width & -remaining_width
        if width > smallest_needed_width:
            return -1

        current = levels[level]
        if width == smallest_needed_width:
            total_weight += current.pop(0)
            remaining_width -= width
            if remaining_width == 0:
                break

        packages = [current[index] + current[index + 1]
                    for index in range(0, len(current) - 1, 2)]
        current.clear()
        next_level = level + 1
        if next_level == len(levels):
            levels.append(packages)
        else:
            existing = levels[next_level]
            merged: list[int] = []
            package_index = 0
            existing_index = 0
            while package_index < len(packages) and existing_index < len(existing):
                if packages[package_index] <= existing[existing_index]:
                    merged.append(packages[package_index])
                    package_index += 1
                else:
                    merged.append(existing[existing_index])
                    existing_index += 1
            merged.extend(packages[package_index:])
            merged.extend(existing[existing_index:])
            levels[next_level] = merged
        level = next_level

    return total_weight
