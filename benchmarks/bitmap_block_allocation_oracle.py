"""Bounded oracle for NBench-style bitmap block-allocation operations."""
from __future__ import annotations
from typing import Sequence

MAX_BITS = 4096
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_BITS // 8


def expected_output(values: Sequence[int] | None, output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None:
        return -1, b""
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    bit_count, operation_count = values[:2]
    if not 1 <= bit_count <= MAX_BITS or not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""
    if len(values) != 2 + 2 * operation_count:
        return -1, b""
    operations = []
    for i in range(operation_count):
        offset, run = values[2 + 2*i:4 + 2*i]
        if offset < 0 or offset > bit_count or run < 0 or run > bit_count - offset:
            return -1, b""
        operations.append((offset, run))
    bits = [index % 2 == 0 for index in range(bit_count)]
    for op_index, (offset, run) in enumerate(operations):
        for bit in range(offset, offset + run):
            if op_index % 3 == 0:
                bits[bit] = True
            elif op_index % 3 == 1:
                bits[bit] = False
            else:
                bits[bit] = not bits[bit]
    output = bytearray((bit_count + 7) // 8)
    for index, value in enumerate(bits):
        if value:
            output[index // 8] |= 1 << (index % 8)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), bytes(output)
