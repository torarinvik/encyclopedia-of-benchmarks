"""Reference trace oracle for the pinned Java fixed-capacity max-heap."""

from __future__ import annotations

import struct

MAX_CAPACITY = 128
MAX_OPERATIONS = 256
MAX_INPUT_VALUES = 515
MAX_OUTPUT_BYTES = 4096
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (bytes_written_or_error, operation status/value byte pairs)."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_VALUES
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""

    capacity, operation_count = values[:2]
    if not 1 <= capacity <= MAX_CAPACITY or not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""
    if len(values) != 2 + 2 * operation_count:
        return -1, b""

    operations: list[tuple[int, int]] = []
    for index in range(operation_count):
        opcode = values[2 + 2 * index]
        argument = values[3 + 2 * index]
        if opcode not in (0, 1, 2, 3, 4, 5):
            return -1, b""
        if opcode == 0:
            if not I32_MIN <= argument <= I32_MAX:
                return -1, b""
        elif argument != 0:
            return -1, b""
        operations.append((opcode, argument))

    if operation_count == 0:
        return 0, b""
    needed = operation_count * 16
    if needed > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return -2, b""

    heap = [0] * (capacity + 1)
    size = 0
    output = bytearray()
    for opcode, argument in operations:
        status = 0
        value = 0
        if opcode == 0:
            if size == capacity:
                status = 1
            else:
                size += 1
                heap[size] = argument
                index = size
                while index > 1 and heap[index // 2] < heap[index]:
                    heap[index // 2], heap[index] = heap[index], heap[index // 2]
                    index //= 2
        elif opcode == 1:
            if size == 0:
                status = 2
            else:
                value = heap[1]
                heap[1] = heap[size]
                heap[size] = 0
                size -= 1
                index = 1
                while index * 2 <= size:
                    child = index * 2
                    if child < size and heap[child + 1] > heap[child]:
                        child += 1
                    if heap[index] >= heap[child]:
                        break
                    heap[index], heap[child] = heap[child], heap[index]
                    index = child
        elif opcode == 2:
            value = 0 if size == 0 else heap[1]
        elif opcode == 3:
            value = int(size == 0)
        elif opcode == 4:
            value = int(size == capacity)
        else:
            value = size
        output.extend(struct.pack("<qq", status, value))
    return len(output), bytes(output)
