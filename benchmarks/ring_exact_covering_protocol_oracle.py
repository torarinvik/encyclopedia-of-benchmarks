"""Primary position-state oracle for the bounded RingCoveringExact profile."""

from __future__ import annotations

from collections.abc import Sequence

SCALE = 16
MAX_N = 12
MAX_STEPS = 64
MAX_INPUT = 3 + MAX_N + MAX_STEPS
MAX_OUTPUT = 8 * (2 + 2 * MAX_N)


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, visibility, steps = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= steps <= MAX_STEPS or len(values) != 3 + n + steps:
        return None
    circumference = SCALE * n
    if not 2 * SCALE <= visibility <= circumference:
        return None
    positions = list(values[3:3 + n])
    if any(not 0 <= p < circumference for p in positions):
        return None
    if any(positions[i] >= positions[i + 1] for i in range(n - 1)):
        return None
    activations = list(values[3 + n:])
    if any(not 0 <= sensor < n for sensor in activations):
        return None
    return n, visibility, positions, activations


def _solve(parsed):
    n, visibility, positions, activations = parsed
    circumference = SCALE * n
    moves = 0
    for sensor in activations:
        successor = (sensor + 1) % n
        gap = (positions[successor] - positions[sensor]) % circumference
        distance = SCALE if gap > visibility else max(0, gap - SCALE)
        if distance:
            positions[sensor] = (positions[sensor] + distance) % circumference
            moves += 1
    gaps = [(positions[(i + 1) % n] - positions[i]) % circumference for i in range(n)]
    return [n, moves, *positions, *gaps]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
