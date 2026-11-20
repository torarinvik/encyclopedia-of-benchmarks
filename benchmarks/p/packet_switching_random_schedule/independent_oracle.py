"""Independent event-record reference for Random Schedule replay."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 68
MAX_OUTPUT_BYTES = 64
MAX_PRIORITY = (1 << 32) - 1


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    m, b, t = values[:3]
    if not 2 <= m <= 4 or not 1 <= b <= 4 or not 1 <= t <= 8:
        return None
    matrix = m * t
    if len(values) != 3 + 2 * matrix:
        return None
    flags, draws = values[3:3 + matrix], values[3 + matrix:]
    if any(flag not in (0, 1) for flag in flags) or any(not 0 <= p <= MAX_PRIORITY for p in draws):
        return None
    return m, b, t, flags, draws


def _run(parsed) -> bytes:
    m, b, t, flags, draws = parsed
    load = [0 for _ in range(m)]
    # Each record has source age and state; list order is the oldest-to-newest order.
    histories: list[list[tuple[int, int, bool]]] = [[] for _ in range(m)]
    trace = []
    for time in range(t):
        for port in range(m):
            cell = time * m + port
            if flags[cell] != 1 or load[port] == b:
                continue
            if len(histories[port]) == b:
                histories[port].pop(0)
            histories[port].append((draws[cell], cell, False))
            load[port] += 1
        candidates = [(-score, port, age) for port in range(m)
                      for score, age, marked in histories[port] if not marked]
        if candidates:
            _, port, age = min(candidates)
            for index, record in enumerate(histories[port]):
                if record[1] == age:
                    score, serial, _ = record
                    histories[port][index] = (score, serial, True)
                    break
        else:
            port = next((i for i in range(m) if load[i]), -1)
        if port < 0:
            trace.append(-1)
        else:
            trace.append(port)
            load[port] -= 1
    return struct.pack("<" + "q" * t, *trace)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _run(parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
