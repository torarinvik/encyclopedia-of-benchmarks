"""Independent oracle for the bounded two-replica LWW element-set trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 24
MAX_VALID_INPUT_LENGTH = 1 + 4 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None) -> list[tuple[int, int, int, int]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 4 * operation_count:
        return None

    operations: list[tuple[int, int, int, int]] = []
    for offset in range(1, len(values), 4):
        opcode, first, second, third = values[offset : offset + 4]
        if opcode not in (0, 1, 2, 3):
            return None
        if opcode in (0, 1):
            if first not in (0, 1) or not I32_MIN <= second <= I32_MAX or not I32_MIN <= third <= I32_MAX:
                return None
        elif opcode == 2:
            if first not in (0, 1) or not I32_MIN <= second <= I32_MAX or third != 0:
                return None
        elif first not in (0, 1) or second not in (0, 1) or third != 0:
            return None
        operations.append((opcode, first, second, third))
    return operations


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    """Pack lookup booleans into low-order bits, or return -1 for invalid input."""
    if type(input_is_null) is not bool or input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values)
    if (
        type(input_length) is not int
        or input_length != len(values)
        or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT

    operations = _parse(values)
    if operations is None:
        return INVALID_RESULT

    replicas: list[tuple[dict[int, int], dict[int, int]]] = [({}, {}), ({}, {})]
    result = 0
    lookup_index = 0
    for opcode, first, second, third in operations:
        if opcode == 0:
            replicas[first][0][second] = third
        elif opcode == 1:
            replicas[first][1][second] = third
        elif opcode == 2:
            add_map, remove_map = replicas[first]
            added_at = add_map.get(second)
            removed_at = remove_map.get(second)
            if added_at is not None and (removed_at is None or added_at > removed_at):
                result |= 1 << lookup_index
            lookup_index += 1
        else:
            target = replicas[first]
            source = replicas[second]
            if first != second:
                for target_map, source_map in zip(target, source):
                    for key, incoming_timestamp in source_map.items():
                        current_timestamp = target_map.get(key)
                        if current_timestamp is None or incoming_timestamp >= current_timestamp:
                            # Equality chooses the incoming entry, matching resolveConflict.
                            target_map[key] = incoming_timestamp
    return result
