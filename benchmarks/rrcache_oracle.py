"""Oracle for a bounded trace through the pinned Java RRCache."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_CAPACITY = 1
MAX_CAPACITY = 8
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 3 + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
JAVA_MULTIPLIER = 0x5DEECE66D
JAVA_ADDEND = 0xB
JAVA_MASK = (1 << 48) - 1
JAVA_INT_MAX = (1 << 31) - 1


class JavaRandom:
    """The specified 48-bit java.util.Random generator for nextInt(bound)."""

    def __init__(self, seed: int):
        self.state = (seed ^ JAVA_MULTIPLIER) & JAVA_MASK

    def _next(self, bits: int) -> int:
        self.state = (self.state * JAVA_MULTIPLIER + JAVA_ADDEND) & JAVA_MASK
        return self.state >> (48 - bits)

    def next_int(self, bound: int) -> int:
        if not 1 <= bound <= (1 << 31) - 1:
            raise ValueError("bound must be a positive signed 32-bit integer")
        if bound & (bound - 1) == 0:
            return (bound * self._next(31)) >> 31
        while True:
            bits = self._next(31)
            value = bits % bound
            # Java rejects when this signed-int expression overflows.
            if bits - value + (bound - 1) <= JAVA_INT_MAX:
                return value


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[tuple[int, int, int]]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    capacity, seed, operation_count = values[:3]
    if not MIN_CAPACITY <= capacity <= MAX_CAPACITY:
        return None
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 3 + 3 * operation_count:
        return None

    operations: list[tuple[int, int, int]] = []
    for offset in range(3, len(values), 3):
        opcode, key, value = values[offset : offset + 3]
        if opcode == 0:
            if not 1 <= key <= 1024 or not 100 <= value <= 1_000_000:
                return None
        elif opcode == 1:
            if not 1 <= key <= 1024 or value != 0:
                return None
        elif opcode == 2:
            if key != 0 or value != 0:
                return None
        else:
            return None
        operations.append((opcode, key, value))
    return capacity, seed, operations


def _trace(capacity: int, seed: int, operations: Sequence[tuple[int, int, int]]) -> list[int]:
    values: dict[int, int] = {}
    insertion_order: list[int] = []
    random = JavaRandom(seed)
    results: list[int] = []

    for opcode, key, value in operations:
        if opcode == 0:
            if key in values:
                # RRCache updates the entry without moving it or drawing.
                values[key] = value
            else:
                if len(values) == capacity:
                    evicted_index = random.next_int(len(insertion_order))
                    evicted_key = insertion_order.pop(evicted_index)
                    del values[evicted_key]
                insertion_order.append(key)
                values[key] = value
            results.append(-2)
        elif opcode == 1:
            results.append(values.get(key, -1))
        else:
            results.append(len(values))
    return results


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return one little-endian signed-i64 result for each trace operation."""
    parsed = _parse(values)
    if parsed is None:
        return None
    capacity, seed, operations = parsed
    output = b"".join(struct.pack("<q", value) for value in _trace(capacity, seed, operations))
    if len(output) > MAX_OUTPUT_BYTES:
        return None
    return output


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and bytes for the signed-i64 array/byte-output ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
