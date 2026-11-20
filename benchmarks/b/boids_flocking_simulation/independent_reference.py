"""Tuple/object-oriented independent reference for Boids integer fixtures."""
from __future__ import annotations

import struct
from typing import Sequence

MAX_BOIDS = 16
MAX_STEPS = 16
MAX_RADIUS = 128
MAX_SPEED = 32
MAX_ACCELERATION = 8
MAX_PARSEABLE_INPUT_LENGTH = 70
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _quotient_toward_zero(value: int, divisor: int) -> int:
    magnitude = abs(value) // divisor
    return -magnitude if value < 0 else magnitude


def _integer_ceiling_length(x: int, y: int) -> int:
    square = x * x + y * y
    estimate = 0
    while estimate * estimate < square:
        estimate += 1
    return estimate


def _limit(x: int, y: int, bound: int) -> tuple[int, int]:
    square = x * x + y * y
    if square <= bound * bound:
        return x, y
    if bound == 0:
        return 0, 0
    divisor = _integer_ceiling_length(x, y)
    return _quotient_toward_zero(x * bound, divisor), _quotient_toward_zero(y * bound, divisor)


def _advance_one(agents: list[tuple[int, int, int, int]], radius: int,
                 speed_bound: int, accel_bound: int) -> list[tuple[int, int, int, int]]:
    result: list[tuple[int, int, int, int]] = []
    radius_sq = radius * radius
    for i, (x, y, vx, vy) in enumerate(agents):
        others: list[tuple[int, int, int, int, int]] = []
        for j, (ox, oy, ovx, ovy) in enumerate(agents):
            if i == j:
                continue
            dx, dy = ox - x, oy - y
            if dx * dx + dy * dy <= radius_sq:
                others.append((j, dx, dy, ovx, ovy))
        if not others:
            result.append((x + vx, y + vy, vx, vy))
            continue

        push_x = push_y = match_x = match_y = center_x = center_y = 0
        for j, dx, dy, ovx, ovy in others:
            square = dx * dx + dy * dy
            if square == 0:
                push_x += -256 if i < j else 256
            else:
                length = _integer_ceiling_length(dx, dy)
                push_x += _quotient_toward_zero(-dx * 256, length)
                push_y += _quotient_toward_zero(-dy * 256, length)
            match_x += ovx
            match_y += ovy
            center_x += dx
            center_y += dy
        count = len(others)

        sep = _limit(_quotient_toward_zero(push_x, count),
                     _quotient_toward_zero(push_y, count), accel_bound)
        align = _limit(_quotient_toward_zero(match_x, count) - vx,
                       _quotient_toward_zero(match_y, count) - vy, accel_bound)
        cohesion = _limit(_quotient_toward_zero(center_x, count),
                          _quotient_toward_zero(center_y, count), accel_bound)

        ax = ay = spent = 0
        for request in (sep, align, cohesion):
            rx, ry = request
            room = accel_bound - spent
            if room <= 0:
                break
            request_len = _integer_ceiling_length(rx, ry)
            if request_len == 0:
                continue
            if request_len <= room:
                ax += rx
                ay += ry
                spent += request_len
            else:
                tx, ty = _limit(rx, ry, room)
                ax += tx
                ay += ty
                break

        nvx, nvy = _limit(vx + ax, vy + ay, speed_bound)
        result.append((x + nvx, y + nvy, nvx, nvy))
    return result


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        input_is_null
        or not isinstance(values, (tuple, list))
        or not 9 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or input_length is not None
        and (type(input_length) is not int or input_length != len(values))
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT, b""
    n, steps, radius, speed, acceleration = values[:5]
    if (
        not 1 <= n <= MAX_BOIDS
        or not 0 <= steps <= MAX_STEPS
        or not 0 <= radius <= MAX_RADIUS
        or not 1 <= speed <= MAX_SPEED
        or not 0 <= acceleration <= MAX_ACCELERATION
        or len(values) != 5 + 4 * n
    ):
        return INVALID_RESULT, b""
    agents = []
    for position in range(5, len(values), 4):
        x, y, vx, vy = values[position:position + 4]
        if (
            not -256 <= x <= 256
            or not -256 <= y <= 256
            or not -32 <= vx <= 32
            or not -32 <= vy <= 32
            or vx * vx + vy * vy > speed * speed
        ):
            return INVALID_RESULT, b""
        agents.append((x, y, vx, vy))
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    required = 16 * n
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR_RESULT, b""
    for _ in range(steps):
        agents = _advance_one(agents, radius, speed, acceleration)
    payload = b"".join(struct.pack("<iiii", *agent) for agent in agents)
    return required, payload
