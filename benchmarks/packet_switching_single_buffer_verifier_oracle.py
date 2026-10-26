"""Independent trace verifier for the bounded FIFO packet policies."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 38
MAX_OUTPUT_BYTES = 64


def _parse(data: Sequence[int] | None):
    if not isinstance(data, (list, tuple)) or not 5 <= len(data) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in data):
        return None
    mode, size, beta, slots, count = data[:5]
    if mode not in (0, 1, 2) or not 1 <= size <= 4 or not 1 <= slots <= 8 or not 0 <= count <= 16:
        return None
    if len(data) != 5 + 2 * count or beta != (0 if mode == 0 else 15):
        return None
    records = tuple((data[5 + 2 * i], data[6 + 2 * i]) for i in range(count))
    if any(t < 0 or t >= slots or v < 1 or v > 100 for t, v in records):
        return None
    if any(records[i][0] > records[i + 1][0] for i in range(count - 1)):
        return None
    return mode, size, slots, records


def _trace(parsed):
    mode, size, slots, records = parsed
    resident: list[tuple[int, int]] = []
    trace: list[int] = []
    cursor = 0
    for tick in range(slots):
        while cursor < len(records) and records[cursor][0] == tick:
            value = records[cursor][1]
            new_packet = (cursor, value)
            # Find the earliest FIFO resident satisfying the policy's threshold.
            target = -1
            if mode == 1:
                target = next((i for i, item in enumerate(resident)
                               if item[1] * 15 <= value), -1)
            elif mode == 2:
                for i, item in enumerate(resident):
                    following_is_large_enough = i + 1 == len(resident) or item[1] <= resident[i + 1][1]
                    if item[1] * 15 < value and following_is_large_enough:
                        target = i
                        break
            if target >= 0:
                del resident[target]
                resident.append(new_packet)
            elif len(resident) != size:
                resident.append(new_packet)
            else:
                floor_value = min(item[1] for item in resident)
                if value > floor_value:
                    drop = next(i for i, item in enumerate(resident) if item[1] == floor_value)
                    del resident[drop]
                    resident.append(new_packet)
            cursor += 1
        trace.append(resident.pop(0)[0] if resident else -1)
    return tuple(trace)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    result = struct.pack("<" + "q" * parsed[2], *_trace(parsed))
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
