"""Bounded trace oracle for the pinned Lua Choiceset data structure."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 1024
MAX_ELEMENTS = 256
MAX_KEY = 1_000_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Execute an add/has/remove/choose trace with explicit one-based draw ranks."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 2 * operation_count):
        return -1, b""

    elements: list[int] = []
    positions: dict[int, int] = {}
    results: list[int] = []
    for offset in range(1, len(values), 2):
        operation, argument = values[offset:offset + 2]
        if operation in (1, 2, 3):
            if not -MAX_KEY <= argument <= MAX_KEY:
                return -1, b""
            index = positions.get(argument)
            if operation == 1:
                if index is not None:
                    results.append(0)
                elif len(elements) == MAX_ELEMENTS:
                    return -1, b""
                else:
                    positions[argument] = len(elements)
                    elements.append(argument)
                    results.append(1)
            elif operation == 2:
                results.append(int(index is not None))
            elif index is None:
                results.append(0)
            else:
                last_index = len(elements) - 1
                if index != last_index:
                    moved = elements[last_index]
                    elements[index] = moved
                    positions[moved] = index
                elements.pop()
                del positions[argument]
                results.append(1)
        elif operation == 4:
            if not 1 <= argument <= len(elements):
                return -1, b""
            results.append(elements[argument - 1])
        else:
            return -1, b""

    output = struct.pack("<" + "q" * len(results), *results)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(output) > capacity:
            return -2, b""
    return len(output), output
