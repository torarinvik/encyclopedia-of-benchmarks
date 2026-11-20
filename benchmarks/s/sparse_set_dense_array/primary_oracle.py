"""Dense/sparse-array primary reference for a bounded dynamic integer set."""

from __future__ import annotations

from collections.abc import Sequence

MIN_UNIVERSE = 1
MAX_UNIVERSE = 32
MAX_OPERATIONS = 30
MAX_VALID_INPUT_LENGTH = 62
MAX_PARSEABLE_INPUT_LENGTH = 63
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[tuple[int, int], ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    universe, count = values[0], values[1]
    if not MIN_UNIVERSE <= universe <= MAX_UNIVERSE:
        return None
    if not 0 <= count <= MAX_OPERATIONS or input_length != 2 + 2 * count:
        return None
    operations: list[tuple[int, int]] = []
    for i in range(count):
        opcode, key = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= opcode <= 3 or not 0 <= key < universe:
            return None
        if opcode == 3 and key != 0:
            return None
        operations.append((opcode, key))
    return universe, tuple(operations)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    universe, operations = parsed
    dense = [0] * universe
    sparse = [universe] * universe
    size = 0
    answers = 0
    for opcode, key in operations:
        index = sparse[key]
        present = index < size and dense[index] == key
        status = 0
        if opcode == 0:
            if not present:
                dense[size] = key
                sparse[key] = size
                size += 1
                status = 1
        elif opcode == 1:
            if present:
                last = dense[size - 1]
                dense[index] = last
                sparse[last] = index
                size -= 1
                status = 1
        elif opcode == 2:
            status = int(present)
        else:
            status = int(size != 0)
            size = 0
        answers = (answers << 1) | status
    final_mask = 0
    for i in range(size):
        final_mask |= 1 << dense[i]
    return (final_mask << len(operations)) | answers
