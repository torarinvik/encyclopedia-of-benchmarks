"""Bitmap-based online reference for bounded deterministic lattice DLA."""

from __future__ import annotations

import struct

MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 280
WORKSPACE_BYTES = 2048
MAX_ATTEMPTS = 16
MAX_STEP_CAP = 512
SIDE = 33
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
GOLDEN = 0x9E3779B97F4A7C15
XORSHIFT_MULTIPLIER = 0x2545F4914F6CDD1D
ZERO_STATE_REPLACEMENT = 0x2545F4914F6CDD1D


def _next(state: int) -> tuple[int, int]:
    state ^= state >> 12
    state &= MASK64
    state ^= (state << 25) & MASK64
    state &= MASK64
    state ^= state >> 27
    state &= MASK64
    return state, (state * XORSHIFT_MULTIPLIER) & MASK64


def _attempt_state(seed: int, attempt: int) -> int:
    state = (seed ^ (GOLDEN * (attempt + 1))) & MASK64
    return state or ZERO_STATE_REPLACEMENT


def _has_neighbor(bitmap: bytearray, x: int, y: int) -> bool:
    if bitmap[y * SIDE + x - 1]:
        return True
    if bitmap[(y - 1) * SIDE + x]:
        return True
    if bitmap[y * SIDE + x + 1]:
        return True
    return bool(bitmap[(y + 1) * SIDE + x])


def _launch(state: int) -> tuple[int, int, int]:
    state, side_word = _next(state)
    state, position_word = _next(state)
    side = side_word % 4
    position = 1 + position_word % 31
    if side == 0:
        return state, position, 1
    if side == 1:
        return state, 31, position
    if side == 2:
        return state, position, 31
    return state, 1, position


def _simulate(attempts: int, seed: int, step_cap: int) -> list[int]:
    bitmap = bytearray(SIDE * SIDE)
    points = [(16, 16)]
    bitmap[16 * SIDE + 16] = 1

    for attempt in range(attempts):
        state, x, y = _launch(_attempt_state(seed, attempt))
        if bitmap[y * SIDE + x]:
            continue
        if _has_neighbor(bitmap, x, y):
            bitmap[y * SIDE + x] = 1
            points.append((x, y))
            continue

        for _ in range(step_cap):
            state, draw = _next(state)
            direction = draw % 4
            if direction == 0:
                x -= 1
            elif direction == 1:
                y -= 1
            elif direction == 2:
                x += 1
            else:
                y += 1
            if x == 0 or x == 32 or y == 0 or y == 32:
                break
            if _has_neighbor(bitmap, x, y):
                bitmap[y * SIDE + x] = 1
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
