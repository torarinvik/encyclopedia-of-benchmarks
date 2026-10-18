"""Oracle for a bounded trace through the pinned Zig Robin Hood hash map."""

from __future__ import annotations

from collections.abc import Sequence
import struct

CAPACITY = 16
MAX_ACTIVE_ENTRIES = 14
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
GOLDEN_RATIO = 0x9E3779B97F4A7C15
U64_MASK = (1 << 64) - 1
U32_MAX = (1 << 32) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
PUT_RESULT = -2
CLEAR_RESULT = -3
MAX_PROBE_DISTANCE = 64


def _hash_key(key: int) -> int:
    high = ((key * GOLDEN_RATIO) & U64_MASK) >> 32
    return high & (CAPACITY - 1)


def _distance(start: int, end: int) -> int:
    return end - start if end >= start else (CAPACITY - start) + end


class _RobinHoodMap:
    def __init__(self) -> None:
        self.entries: list[tuple[int, int, int] | None] = [None] * CAPACITY
        self.count = 0

    def put(self, key: int, value: int) -> None:
        # The pinned implementation performs this check before searching for
        # an existing key. Workload bounds keep it false for every operation.
        if (self.count * 100) // CAPACITY >= 90:
            raise ValueError("HashMapFull")
        entry = (key, value, 0)
        index = _hash_key(key)
        probes = 0
        while probes < MAX_PROBE_DISTANCE:
            resident = self.entries[index]
            if resident is None:
                self.entries[index] = entry
                self.count += 1
                return
            if resident[0] == key:
                self.entries[index] = (resident[0], value, resident[2])
                return
            if entry[2] > resident[2]:
                self.entries[index], entry = entry, resident
            entry = (entry[0], entry[1], entry[2] + 1)
            index = (index + 1) & (CAPACITY - 1)
            probes += 1
        raise ValueError("ProbeDistanceExceeded")

    def get(self, key: int) -> int | None:
        index = _hash_key(key)
        probe_distance = 0
        while probe_distance < MAX_PROBE_DISTANCE:
            resident = self.entries[index]
            if resident is None:
                return None
            if resident[0] == key:
                return resident[1]
            if probe_distance > resident[2]:
                return None
            index = (index + 1) & (CAPACITY - 1)
            probe_distance += 1
        return None

    def remove(self, key: int) -> bool:
        index = _hash_key(key)
        probe_distance = 0
        while probe_distance < MAX_PROBE_DISTANCE:
            resident = self.entries[index]
            if resident is None:
                return False
            if resident[0] == key:
                self._backshift(index)
                self.count -= 1
                return True
            if probe_distance > resident[2]:
                return False
            index = (index + 1) & (CAPACITY - 1)
            probe_distance += 1
        return False

    def _backshift(self, start: int) -> None:
        index = start
        for _ in range(CAPACITY):
            next_index = (index + 1) & (CAPACITY - 1)
            following = self.entries[next_index]
            if following is None or following[2] == 0:
                self.entries[index] = None
                return
            self.entries[index] = (following[0], following[1], following[2] - 1)
            index = next_index
        raise AssertionError("source backshift bound should not be reached")

    def clear(self) -> None:
        self.entries = [None] * CAPACITY
        self.count = 0

    def max_psl(self) -> int:
        return max((entry[2] for entry in self.entries if entry is not None), default=0)


def _parse(values: Sequence[int] | None) -> list[tuple[int, int, int]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 3 * operation_count:
        return None
    operations: list[tuple[int, int, int]] = []
    for offset in range(1, len(values), 3):
        opcode, key, value = values[offset : offset + 3]
        if opcode == 0:
            if not 0 <= key <= U32_MAX or not 100 <= value <= 1_000_000:
                return None
        elif opcode in (1, 2):
            if not 0 <= key <= U32_MAX or value != 0:
                return None
        elif opcode in (3, 4, 5, 6, 7):
            if key != 0 or value != 0:
                return None
        else:
            return None
        operations.append((opcode, key, value))
    return operations


def _run(operations: Sequence[tuple[int, int, int]]) -> list[int] | None:
    table = _RobinHoodMap()
    results: list[int] = []
    try:
        for opcode, key, value in operations:
            if opcode == 0:
                table.put(key, value)
                # The benchmark intentionally stays at or below 14/16 live
                # entries, keeping all puts below the source load guard.
                if table.count > MAX_ACTIVE_ENTRIES:
                    return None
                results.append(PUT_RESULT)
            elif opcode == 1:
                result = table.get(key)
                results.append(-1 if result is None else result)
            elif opcode == 2:
                results.append(1 if table.remove(key) else 0)
            elif opcode == 3:
                results.append(table.count)
            elif opcode == 4:
                results.append((table.count * 100) // CAPACITY)
            elif opcode == 5:
                results.append(table.max_psl())
            elif opcode == 6:
                table.clear()
                results.append(CLEAR_RESULT)
            else:
                results.append(1 if table.count == 0 else 0)
    except ValueError:
        return None
    return results


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return one little-endian signed-i64 result for each operation."""
    operations = _parse(values)
    if operations is None:
        return None
    results = _run(operations)
    if results is None:
        return None
    output = b"".join(struct.pack("<q", result) for result in results)
    return output if len(output) <= MAX_OUTPUT_BYTES else None


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
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
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
