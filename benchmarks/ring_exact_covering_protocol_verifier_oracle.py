"""Independent gap-state oracle for RingCoveringExact activation traces."""

from __future__ import annotations

from collections.abc import Sequence

SCALE = 16
MAX_N = 12
MAX_STEPS = 64
MAX_INPUT = 3 + MAX_N + MAX_STEPS
MAX_OUTPUT = 8 * (2 + 2 * MAX_N)


def _simulate(n, visibility, positions, activations):
    circumference = SCALE * n
    gaps = [(positions[(i + 1) % n] - positions[i]) % circumference for i in range(n)]
    displacement = [0] * n
    moves = 0
    for sensor in activations:
        gap = gaps[sensor]
        shift = SCALE if gap > visibility else max(0, gap - SCALE)
        if shift:
            gaps[sensor] -= shift
            gaps[(sensor + 1) % n] += shift
            displacement[sensor] += shift
            moves += 1
    final_positions = [(positions[i] + displacement[i]) % circumference for i in range(n)]
    return [n, moves, *final_positions, *gaps]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    n, visibility, steps = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= steps <= MAX_STEPS or len(values) != 3 + n + steps:
        return -1, b""
    circumference = SCALE * n
    positions = list(values[3:3 + n])
    activations = list(values[3 + n:])
    if (not 2 * SCALE <= visibility <= circumference
            or any(not 0 <= p < circumference for p in positions)
            or any(positions[i] >= positions[i + 1] for i in range(n - 1))
            or any(not 0 <= sensor < n for sensor in activations)):
        return -1, b""
    result = _simulate(n, visibility, positions, activations)
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
