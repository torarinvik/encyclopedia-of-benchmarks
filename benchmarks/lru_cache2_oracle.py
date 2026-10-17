"""Oracle for the bounded pinned C++ LRUCache operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
PUT_SENTINEL = I64_MIN
MIN_CAPACITY = 2
MAX_CAPACITY = 64
MAX_OPERATIONS = 256
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _execute(values: Sequence[int]) -> list[int] | None:
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    capacity, operation_count = values[:2]
    if not MIN_CAPACITY <= capacity <= MAX_CAPACITY:
        return None
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + 3 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return None

    cache: dict[int, int] = {}
    mru_to_lru: list[int] = []
    seen_put_keys: set[int] = set()
    answers: list[int] = []
    cursor = 2
    for _ in range(operation_count):
        opcode, arg1, arg2 = values[cursor : cursor + 3]
        cursor += 3
        if opcode == 0:  # put(key, value)
            key, value = arg1, arg2
            if not I32_MIN <= key <= I32_MAX or not I32_MIN <= value <= I32_MAX:
                return None
            if key in seen_put_keys:
                return None
            seen_put_keys.add(key)
            if len(cache) == capacity:
                evicted = mru_to_lru.pop()
                del cache[evicted]
            cache[key] = value
            mru_to_lru.insert(0, key)
            answers.append(PUT_SENTINEL)
        elif opcode == 1:  # get(key)
            key = arg1
            if not I32_MIN <= key <= I32_MAX or arg2 != 0 or key not in cache:
                return None
            value = cache[key]
            mru_to_lru.remove(key)
            mru_to_lru.insert(0, key)
            answers.append(value)
        elif opcode in (2, 3, 4):
            if arg1 != 0 or arg2 != 0:
                return None
            if opcode == 2:  # size()
                answers.append(len(cache))
            elif opcode == 3:  # capacity()
                answers.append(capacity)
            else:  # empty()
                answers.append(1 if not cache else 0)
        else:
            return None
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return one signed-i64 API observation per operation, or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    answers = _execute(values)
    if answers is None:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
