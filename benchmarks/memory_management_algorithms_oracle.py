"""Oracle for the four pinned Java memory-allocation policies."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_BLOCK_COUNT = 16
MAX_PROCESS_COUNT = 32
MAX_INPUT_LENGTH = 3 + MAX_BLOCK_COUNT + MAX_PROCESS_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_SIZE = 10_000
MAX_OUTPUT_BYTES = MAX_PROCESS_COUNT * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
NO_ALLOCATION = -255


def _simulate(values: Sequence[int]) -> bytes | None:
    if (not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    policy, block_count, process_count = values[:3]
    if policy not in (0, 1, 2, 3):
        return None
    if not 1 <= block_count <= MAX_BLOCK_COUNT or not 0 <= process_count <= MAX_PROCESS_COUNT:
        return None
    if len(values) != 3 + block_count + process_count:
        return None
    blocks = list(values[3:3 + block_count])
    processes = list(values[3 + block_count:])
    if (any(not 1 <= size <= MAX_SIZE for size in blocks)
            or any(not 1 <= size <= MAX_SIZE for size in processes)):
        return None

    results: list[int] = []
    counter = 0
    for process in processes:
        selected = NO_ALLOCATION
        if policy == 0:
            for index, block in enumerate(blocks):
                if block >= process:
                    selected = index
                    break
        elif policy == 1:
            min_diff = max(blocks)
            for index, block in enumerate(blocks):
                difference = block - process
                if difference < min_diff and difference >= 0:
                    min_diff = difference
                    selected = index
        elif policy == 2:
            index = max(range(block_count), key=lambda item: blocks[item])
            if process <= blocks[index]:
                selected = index
        else:
            for offset in range(block_count):
                if counter + offset >= block_count:
                    counter = -offset
                index = offset + counter
                if blocks[index] >= process:
                    counter += offset
                    selected = counter
                    break
            else:
                counter += block_count

        results.append(selected)
        if selected != NO_ALLOCATION:
            blocks[selected] -= process

    if not results:
        return b""
    return struct.pack("<" + "q" * len(results), *results)


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
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    output = _simulate(values)
    if output is None:
        return INVALID_RESULT, b""
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
