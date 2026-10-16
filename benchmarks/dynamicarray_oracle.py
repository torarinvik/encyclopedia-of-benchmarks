"""Oracle for the bounded Go-style dynamic-array operation trace."""

from __future__ import annotations

import struct

MAX_OPERATIONS = 128
MAX_ELEMENTS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = (3 + MAX_OPERATIONS + MAX_ELEMENTS) * 8
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_output(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""
    state: list[int] = []
    capacity = 0
    results: list[int] = []
    cursor = 1
    for _ in range(operation_count):
        if cursor >= len(values):
            return -1, b""
        op = values[cursor]
        cursor += 1
        if op == 0:  # append
            if cursor >= len(values) or len(state) >= MAX_ELEMENTS:
                return -1, b""
            if len(state) == capacity:
                capacity = 10 if capacity == 0 else capacity * 2
            state.append(values[cursor])
            cursor += 1
        elif op == 1:  # update
            if cursor + 1 >= len(values):
                return -1, b""
            index, value = values[cursor:cursor + 2]
            cursor += 2
            if not 0 <= index < len(state):
                return -1, b""
            state[index] = value
        elif op in (2, 3):  # get, remove
            if cursor >= len(values):
                return -1, b""
            index = values[cursor]
            cursor += 1
            if not 0 <= index < len(state):
                return -1, b""
            if op == 2:
                results.append(state[index])
            else:
                state.pop(index)
        elif op == 4:
            results.append(len(state))
        elif op == 5:
            results.append(capacity)
        elif op == 6:
            results.append(int(len(state) == 0))
        else:
            return -1, b""
    if cursor != len(values):
        return -1, b""
    words = [len(results), *results, len(state), capacity, *state]
    output = struct.pack("<" + "q" * len(words), *words)
    return len(words), output
