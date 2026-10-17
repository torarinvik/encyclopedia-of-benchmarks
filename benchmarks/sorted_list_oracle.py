"""Independent operation-trace oracle for the sorted-list contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 512
MAX_SIZE = 256
MAX_VALUE = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 2 * MAX_OPERATIONS + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OFFSET = 1_000_000


def expected_result(values: Sequence[int] | None) -> int:
    """Return the trace checksum, or -1 when framing or an operation is invalid."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or len(values) % 2 != 0
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    operation_count = len(values) // 2
    if operation_count > MAX_OPERATIONS:
        return INVALID_RESULT

    items: list[int] = []
    checksum = 0
    for operation_index in range(operation_count):
        opcode, payload = values[2 * operation_index : 2 * operation_index + 2]
        observed: int | None

        if opcode == 0:
            if not 0 <= payload <= MAX_VALUE or len(items) >= MAX_SIZE:
                return INVALID_RESULT
            items.append(payload)
            items.sort()
            observed = None
        elif opcode == 1:
            if not 0 <= payload <= MAX_VALUE:
                return INVALID_RESULT
            observed = int(payload in items)
        elif opcode == 2:
            if not 0 <= payload <= MAX_VALUE:
                return INVALID_RESULT
            found = payload in items
            if found:
                items.remove(payload)
            observed = int(found)
        elif opcode == 3:
            if payload != 0:
                return INVALID_RESULT
            observed = len(items)
        elif opcode == 4:
            if not 0 <= payload < len(items):
                return INVALID_RESULT
            observed = items[payload]
        elif opcode == 5:
            if payload != 0:
                return INVALID_RESULT
            items.clear()
            observed = None
        else:
            return INVALID_RESULT

        if observed is not None:
            checksum += (operation_index + 1) * (observed + OFFSET)

    for position, item in enumerate(items, start=1):
        checksum += (operation_count + position) * (item + OFFSET)
    return checksum
