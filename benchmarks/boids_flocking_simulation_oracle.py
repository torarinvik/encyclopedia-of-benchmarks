"""Array-oriented reference for the bounded integer Boids profile."""
from __future__ import annotations

import struct
import math
from typing import Sequence

MAX_BOIDS = 16
MAX_STEPS = 16
MAX_RADIUS = 128
MAX_SPEED = 32
MAX_ACCELERATION = 8
MAX_VALID_INPUT_LENGTH = 5 + 4 * MAX_BOIDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16 * MAX_BOIDS
WORKSPACE_BYTES = 1280
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
SEPARATION_SCALE = 256


def _trunc_zero(numerator: int, denominator: int) -> int:
    if numerator < 0:
        return -((-numerator) // denominator)
    return numerator // denominator


def _ceil_sqrt(value: int) -> int:
    if value == 0:
        return 0
    root = math.isqrt(value)
    return root if root * root == value else root + 1


def _cap_vector(x: int, y: int, limit: int) -> tuple[int, int]:
    squared = x * x + y * y
    if squared <= limit * limit:
        return x, y
    if limit == 0:
        return 0, 0
    length = _ceil_sqrt(squared)
    return _trunc_zero(x * limit, length), _trunc_zero(y * limit, length)


def _request_vectors(
    index: int,
    xs: list[int],
    ys: list[int],
    vxs: list[int],
    vys: list[int],
    radius_squared: int,
    max_acceleration: int,
) -> tuple[int, int]:
    separation_x = separation_y = 0
    velocity_x = velocity_y = 0
    offset_x = offset_y = 0
    neighbor_count = 0

    for other in range(len(xs)):
        if other == index:
            continue
        dx = xs[other] - xs[index]
        dy = ys[other] - ys[index]
        distance_squared = dx * dx + dy * dy
        if distance_squared > radius_squared:
            continue
        neighbor_count += 1
        if distance_squared == 0:
            away_x = -SEPARATION_SCALE if index < other else SEPARATION_SCALE
            away_y = 0
        else:
            length = _ceil_sqrt(distance_squared)
            away_x = _trunc_zero(-dx * SEPARATION_SCALE, length)
            away_y = _trunc_zero(-dy * SEPARATION_SCALE, length)
        separation_x += away_x
        separation_y += away_y
        velocity_x += vxs[other]
        velocity_y += vys[other]
        offset_x += dx
        offset_y += dy

    if neighbor_count == 0:
        return 0, 0

    separation = _cap_vector(
        _trunc_zero(separation_x, neighbor_count),
        _trunc_zero(separation_y, neighbor_count),
        max_acceleration,
    )
    alignment = _cap_vector(
        _trunc_zero(velocity_x, neighbor_count) - vxs[index],
        _trunc_zero(velocity_y, neighbor_count) - vys[index],
        max_acceleration,
    )
    cohesion = _cap_vector(
        _trunc_zero(offset_x, neighbor_count),
        _trunc_zero(offset_y, neighbor_count),
        max_acceleration,
    )

    accel_x = accel_y = used = 0
    for request_x, request_y in (separation, alignment, cohesion):
        remaining = max_acceleration - used
        if remaining <= 0:
            break
        request_length = _ceil_sqrt(request_x * request_x + request_y * request_y)
        if request_length == 0:
            continue
        if request_length <= remaining:
            accel_x += request_x
            accel_y += request_y
            used += request_length
        else:
            trim_x, trim_y = _cap_vector(request_x, request_y, remaining)
            accel_x += trim_x
            accel_y += trim_y
            break
    return accel_x, accel_y


def _run(values: Sequence[int]) -> bytes:
    boid_count, steps, radius, max_speed, max_acceleration = values[:5]
    states = [values[5 + 4 * i:9 + 4 * i] for i in range(boid_count)]
    xs = [state[0] for state in states]
    ys = [state[1] for state in states]
    vxs = [state[2] for state in states]
    vys = [state[3] for state in states]
    radius_squared = radius * radius

    for _ in range(steps):
        next_xs = [0] * boid_count
        next_ys = [0] * boid_count
        next_vxs = [0] * boid_count
        next_vys = [0] * boid_count
        for index in range(boid_count):
            accel_x, accel_y = _request_vectors(
                index, xs, ys, vxs, vys, radius_squared, max_acceleration
            )
            next_vx, next_vy = _cap_vector(
                vxs[index] + accel_x, vys[index] + accel_y, max_speed
            )
            next_xs[index] = xs[index] + next_vx
            next_ys[index] = ys[index] + next_vy
            next_vxs[index] = next_vx
            next_vys[index] = next_vy
        xs, ys, vxs, vys = next_xs, next_ys, next_vxs, next_vys

    return b"".join(
        struct.pack("<iiii", xs[i], ys[i], vxs[i], vys[i])
        for i in range(boid_count)
    )


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
    boid_count, steps, radius, max_speed, max_acceleration = values[:5]
    if (
        not 1 <= boid_count <= MAX_BOIDS
        or not 0 <= steps <= MAX_STEPS
        or not 0 <= radius <= MAX_RADIUS
        or not 1 <= max_speed <= MAX_SPEED
        or not 0 <= max_acceleration <= MAX_ACCELERATION
        or len(values) != 5 + 4 * boid_count
    ):
        return INVALID_RESULT, b""
    for index in range(boid_count):
        x, y, vx, vy = values[5 + 4 * index:9 + 4 * index]
        if (
            not -256 <= x <= 256
            or not -256 <= y <= 256
            or not -32 <= vx <= 32
            or not -32 <= vy <= 32
            or vx * vx + vy * vy > max_speed * max_speed
        ):
            return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    required = 16 * boid_count
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR_RESULT, b""
    return required, _run(values)
