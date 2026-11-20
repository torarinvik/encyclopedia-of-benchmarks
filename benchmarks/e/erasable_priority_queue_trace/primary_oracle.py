"""Array-backed two-heap reference for a bounded erasable-min-queue trace."""

from __future__ import annotations

from collections.abc import Sequence
from heapq import heappop, heappush

MAX_OPERATIONS = 63
MAX_VALUE = 100
MIN_VALUE = -100
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096
MAX_RESULT = 807 * (MAX_OPERATIONS * (MAX_OPERATIONS + 1) // 2)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 1 + 2 * operation_count:
        return None

    operations: list[tuple[int, int]] = []
    for offset in range(1, len(values), 2):
        opcode, value = values[offset], values[offset + 1]
        if opcode == 0 or opcode == 1:
            if not MIN_VALUE <= value <= MAX_VALUE:
                return None
        elif opcode == 2 or opcode == 3:
            if value != 0:
                return None
        else:
            return None
        operations.append((opcode, value))
    return operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the weighted operation trace, or -1 for an invalid request."""
    operations = _decode(values, input_length, input_is_null)
    if operations is None:
        return -1

    live: list[int] = []
    deleted: list[int] = []
    counts: dict[int, int] = {}
    checksum = 0
    for index, (opcode, value) in enumerate(operations, start=1):
        response = 0
        if opcode == 0:
            heappush(live, value)
            counts[value] = counts.get(value, 0) + 1
        elif opcode == 1:
            count = counts.get(value, 0)
            if count == 0:
                return -1
            if count == 1:
                del counts[value]
            else:
                counts[value] = count - 1
            heappush(deleted, value)
            response = 1
        else:
            while live and deleted and live[0] == deleted[0]:
                heappop(live)
                heappop(deleted)
            if opcode == 2:
                response = live[0] if live else -101
            elif live:
                response = heappop(live)
                counts[response] -= 1
                if counts[response] == 0:
                    del counts[response]
            else:
                return -1
        token = opcode * 202 + response + 101
        checksum += index * token
    return checksum
