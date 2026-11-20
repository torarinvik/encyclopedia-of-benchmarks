"""Opacity-pyramid oracle for the bounded clean-room volume ray-march profile."""

from __future__ import annotations

MAX_SIDE = 8
MAX_RAYS = 16
MAX_SAMPLES = 32
MAX_VOXELS = MAX_SIDE ** 3
MAX_VALID_INPUT_VALUES = 3 + 2 * MAX_VOXELS + 6 * MAX_RAYS
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 5 * MAX_RAYS
MAX_SCRATCH_BYTES = MAX_VOXELS * 2 + 4 * MAX_SIDE ** 3 + 6 * MAX_RAYS * 4
Q8 = 256
Q16 = 1 << 16
WEIGHT_DENOMINATOR = 1 << 24
ALPHA_DENOMINATOR = 255 * WEIGHT_DENOMINATOR
COLOR_DENOMINATOR = 255 * 255 * WEIGHT_DENOMINATOR


def _round_half_up(numerator: int, denominator: int) -> int:
    return (numerator + denominator // 2) // denominator


def _parse(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_VALUES):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length < 3):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None

    side, ray_count, sample_count = values[:3]
    if side not in (2, 4, 8) or not 1 <= ray_count <= MAX_RAYS \
            or not 1 <= sample_count <= MAX_SAMPLES:
        return None
    voxel_count = side ** 3
    if len(values) != 3 + 2 * voxel_count + 6 * ray_count:
        return None

    alpha = [0] * voxel_count
    gray = [0] * voxel_count
    at = 3
    for index in range(voxel_count):
        alpha[index], gray[index] = values[at], values[at + 1]
        if not 0 <= alpha[index] <= 255 or not 0 <= gray[index] <= 255:
            return None
        at += 2

    coordinate_max = (side - 1) * Q8
    rays = []
    for _ in range(ray_count):
        x0, y0, z0, dx, dy, dz = values[at:at + 6]
        at += 6
        origin = (x0, y0, z0)
        step = (dx, dy, dz)
        if any(not 0 <= coordinate <= coordinate_max for coordinate in origin):
            return None
        if any(not -coordinate_max <= delta <= coordinate_max for delta in step):
            return None
        if sample_count > 1 and dx == 0 and dy == 0 and dz == 0:
            return None
        for sample in range(sample_count):
            point = tuple(origin[axis] + sample * step[axis] for axis in range(3))
            if any(not 0 <= coordinate <= coordinate_max for coordinate in point):
                return None
        rays.append((origin, step))
    return side, ray_count, sample_count, alpha, gray, rays


def _index(side: int, x: int, y: int, z: int) -> int:
    return (z * side + y) * side + x


def _trilinear(side: int, alpha: list[int], gray: list[int],
               xq: int, yq: int, zq: int) -> tuple[int, int]:
    points = (xq, yq, zq)
    lower = [point // Q8 for point in points]
    fraction = [point % Q8 for point in points]
    upper = [min(lower[axis] + 1, side - 1) for axis in range(3)]
    opacity_sum = 0
    premultiplied_gray_sum = 0
    for dz in range(2):
        wz = fraction[2] if dz else Q8 - fraction[2]
        z = upper[2] if dz else lower[2]
        for dy in range(2):
            wy = fraction[1] if dy else Q8 - fraction[1]
            y = upper[1] if dy else lower[1]
            for dx in range(2):
                wx = fraction[0] if dx else Q8 - fraction[0]
                x = upper[0] if dx else lower[0]
                weight = wx * wy * wz
                at = _index(side, x, y, z)
                opacity_sum += alpha[at] * weight
                premultiplied_gray_sum += alpha[at] * gray[at] * weight
    opacity_q16 = _round_half_up(opacity_sum * Q16, ALPHA_DENOMINATOR)
    premultiplied_gray_q16 = _round_half_up(
        premultiplied_gray_sum * Q16, COLOR_DENOMINATOR)
    return opacity_q16, premultiplied_gray_q16


def _opacity_pyramid(side: int, alpha: list[int]) -> list[tuple[int, list[int]]]:
    levels: list[tuple[int, list[int]]] = []
    support = [0] * (side ** 3)
    for z in range(side):
        for y in range(side):
            for x in range(side):
                occupied = 0
                for dz in range(2):
                    for dy in range(2):
                        for dx in range(2):
                            nx = min(x + dx, side - 1)
                            ny = min(y + dy, side - 1)
                            nz = min(z + dz, side - 1)
                            occupied |= int(alpha[_index(side, nx, ny, nz)] > 0)
                support[_index(side, x, y, z)] = occupied
    levels.append((side, support))

    dimension = side
    while dimension > 1:
        parent_dimension = dimension // 2
        children = levels[-1][1]
        parents = [0] * (parent_dimension ** 3)
        for z in range(parent_dimension):
            for y in range(parent_dimension):
                for x in range(parent_dimension):
                    occupied = 0
                    for dz in range(2):
                        for dy in range(2):
                            for dx in range(2):
                                child = _index(dimension, 2 * x + dx,
                                               2 * y + dy, 2 * z + dz)
                                occupied |= children[child]
                    parents[_index(parent_dimension, x, y, z)] = occupied
        levels.append((parent_dimension, parents))
        dimension = parent_dimension
    return levels


def _ray_pixel(side: int, sample_count: int, alpha: list[int], gray: list[int],
               levels: list[tuple[int, list[int]]], origin: tuple[int, int, int],
               step: tuple[int, int, int]) -> bytes:
    accumulated_alpha = 0
    accumulated_gray = 0
    used = 0
    for sample in range(sample_count):
        used = sample + 1
        point = tuple(origin[axis] + sample * step[axis] for axis in range(3))
        cell = tuple(coordinate // Q8 for coordinate in point)
        supported = True
        for level in range(len(levels) - 1, -1, -1):
            dimension, mask = levels[level]
            shift = level
            node = _index(dimension, cell[0] >> shift,
                          cell[1] >> shift, cell[2] >> shift)
            if mask[node] == 0:
                supported = False
                break
        if supported:
            sample_alpha, sample_gray = _trilinear(
                side, alpha, gray, point[0], point[1], point[2])
            remaining = Q16 - accumulated_alpha
            accumulated_alpha = min(
                Q16, accumulated_alpha + _round_half_up(
                    remaining * sample_alpha, Q16))
            accumulated_gray = min(
                Q16, accumulated_gray + _round_half_up(
                    remaining * sample_gray, Q16))
            if accumulated_alpha == Q16:
                break

    gray_byte = (accumulated_gray * 255 + Q16 // 2) // Q16
    alpha_byte = (accumulated_alpha * 255 + Q16 // 2) // Q16
    return bytes((gray_byte, gray_byte, gray_byte, alpha_byte, used))


def expected_output(values, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    side, ray_count, sample_count, alpha, gray, rays = parsed
    required = 5 * ray_count
    if output_is_null:
        return -2, b""
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < required):
        return -3, b""

    levels = _opacity_pyramid(side, alpha)
    payload = b"".join(
        _ray_pixel(side, sample_count, alpha, gray, levels, origin, step)
        for origin, step in rays)
    return required, payload
