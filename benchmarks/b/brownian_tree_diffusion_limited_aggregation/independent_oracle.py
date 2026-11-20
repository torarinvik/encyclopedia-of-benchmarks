"""Path-precomputation and occupied-point-list reference for bounded DLA."""

from __future__ import annotations

import struct

MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 280
WORKSPACE_BYTES = 2048
MAX_ATTEMPTS = 16
MAX_STEP_CAP = 512
GRID_MAX = 32
MASK64 = (1 << 64) - 1
GOLDEN = 0x9E3779B97F4A7C15
MULTIPLIER = 0x2545F4914F6CDD1D
ZERO_STATE = 0x2545F4914F6CDD1D


def _advance(state: int) -> tuple[int, int]:
    state ^= state >> 12
    state &= MASK64
    state ^= state << 25
    state &= MASK64
    state ^= state >> 27
    state &= MASK64
    return state, state * MULTIPLIER & MASK64


def _random_state(seed: int, attempt: int) -> int:
    value = (seed ^ (GOLDEN * (attempt + 1))) & MASK64
    return value if value else ZERO_STATE


def _precompute_paths(attempts: int, seed: int, step_cap: int) -> list[list[tuple[int, int]]]:
    all_paths: list[list[tuple[int, int]]] = []
    for attempt in range(attempts):
        state = _random_state(seed, attempt)
        state, side_word = _advance(state)
        state, position_word = _advance(state)
        side = side_word % 4
        position = 1 + position_word % 31
        if side == 0:
            x, y = position, 1
        elif side == 1:
            x, y = 31, position
        elif side == 2:
            x, y = position, 31
        else:
            x, y = 1, position
        path = [(x, y)]
        for _ in range(step_cap):
            state, draw = _advance(state)
            direction = draw % 4
            if direction == 0:
                x -= 1
            elif direction == 1:
                y -= 1
            elif direction == 2:
                x += 1
            else:
                y += 1
            if x == 0 or x == GRID_MAX or y == 0 or y == GRID_MAX:
                break
            path.append((x, y))
        all_paths.append(path)
    return all_paths


def _touches(points: list[tuple[int, int]], x: int, y: int) -> bool:
    for occupied_x, occupied_y in points:
        if (occupied_x == x - 1 and occupied_y == y
                or occupied_x == x and occupied_y == y - 1
                or occupied_x == x + 1 and occupied_y == y
                or occupied_x == x and occupied_y == y + 1):
            return True
    return False


def _simulate(attempts: int, seed: int, step_cap: int) -> list[int]:
    points = [(16, 16)]
    for path in _precompute_paths(attempts, seed, step_cap):
        launch_x, launch_y = path[0]
        if (launch_x, launch_y) in points:
            continue
        for x, y in path:
            if _touches(points, x, y):
                points.append((x, y))
                break
    return [len(points), *(coordinate for point in points for coordinate in point)]


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(input_values, (list, tuple))
        or not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH
        or length != len(input_values)
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in input_values)
    ):
        return -1, b""
    if length != 3:
        return -1, b""
    attempts, seed, step_cap = input_values
    if not 0 <= attempts <= MAX_ATTEMPTS or not 1 <= seed <= (1 << 63) - 1 or not 1 <= step_cap <= MAX_STEP_CAP:
        return -1, b""

    words = _simulate(attempts, seed, step_cap)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (
        type(output_is_null) is not bool
        or output_is_null
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < len(payload))
    ):
        return -2, b""
    return len(payload), payload
