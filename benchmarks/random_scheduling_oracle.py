"""Oracle for the pinned Java RandomScheduling permutation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TASK_COUNT = 32
MAX_VALID_INPUT_LENGTH = MAX_TASK_COUNT + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TASK_COUNT * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_MULTIPLIER = 0x5DEECE66D
_ADDEND = 0xB
_MASK = (1 << 48) - 1


class _JavaRandom:
    def __init__(self, seed: int) -> None:
        self.state = (seed ^ _MULTIPLIER) & _MASK

    def next(self, bits: int) -> int:
        self.state = (self.state * _MULTIPLIER + _ADDEND) & _MASK
        return self.state >> (48 - bits)

    def next_int(self, bound: int) -> int:
        if bound <= 0:
            raise ValueError("bound must be positive")
        if bound & (bound - 1) == 0:
            return (bound * self.next(31)) >> 31
        while True:
            bits = self.next(31)
            value = bits % bound
            # Java evaluates this rejection test with signed 32-bit overflow.
            if bits - value + (bound - 1) <= (1 << 31) - 1:
                return value


def _simulate(seed: int, tasks: Sequence[int]) -> bytes:
    result = list(tasks)
    random = _JavaRandom(seed)
    for size in range(len(result), 1, -1):
        selected = random.next_int(size)
        result[size - 1], result[selected] = result[selected], result[size - 1]
    if not result:
        return b""
    return struct.pack("<" + "q" * len(result), *result)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    seed, task_count = values[:2]
    if not 0 <= task_count <= MAX_TASK_COUNT or len(values) != task_count + 2:
        return INVALID_RESULT, b""
    tasks = values[2:]
    if any(not I32_MIN <= task <= I32_MAX for task in tasks):
        return INVALID_RESULT, b""
    output = _simulate(seed, tasks)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
