"""Independent oracle for the bounded, deterministic FreeBench Distray profile.

The pinned C file has no explicit license grant. This oracle is an independent
mathematical model; upstream authors are credited in the package README.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Sequence

WIDTH = 640
HEIGHT = 480
MIN_DISTRIBUTION = 1
MAX_DISTRIBUTION = 5
MAX_OUTPUT_BYTES = 3
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1
OUTPUT_ERROR = -2
EPSILON = 1.0e-5
MAX_T = 1.0e5
MAX_REC = 6
DIST_LEVELS = 3
SEED = 0x52462467


@dataclass(frozen=True)
class Vec3:
    x: float
    y: float
    z: float


@dataclass(frozen=True)
class Texture:
    color: Vec3
    diffuse: float
    reflect: float
    roughness: float


@dataclass(frozen=True)
class Sphere:
    center: Vec3
    radius: float
    texture: Texture


@dataclass
class TraceContext:
    distribution: int
    random_state: int = SEED


SPHERES = (
    Sphere(Vec3(0.0, 4.0, 1.0), 1.0, Texture(Vec3(1.0, 0.4, 0.0), 0.4, 0.8, 0.02)),
    Sphere(Vec3(-1.0, 3.0, 0.4), 0.4, Texture(Vec3(0.5, 0.3, 1.0), 0.5, 0.9, 0.01)),
    Sphere(Vec3(-0.3, 1.0, 0.4), 0.4, Texture(Vec3(0.1, 0.95, 0.2), 0.6, 0.8, 0.01)),
    Sphere(Vec3(1.0, 2.0, 0.4), 0.4, Texture(Vec3(0.86, 0.83, 0.0), 0.7, 0.6, 0.01)),
)
GROUND = (
    Texture(Vec3(0.0, 0.1, 0.5), 0.8, 0.44, 0.02),
    Texture(Vec3(0.6, 1.0, 0.5), 0.8, 0.44, 0.01),
)
LIGHT = Vec3(-3.0, 1.0, 5.0)
CAMERA = Vec3(1.5, -1.4, 1.2)
CAMERA_RIGHT = Vec3(3.0, 1.0, 0.0)
CAMERA_DIR = Vec3(-1.0, 3.0, 0.0)
CAMERA_UP = Vec3(0.0, 0.0, 2.3717)
SKY_HORIZON = Vec3(0.5, 0.3, 0.7)
SKY_ZENITH = Vec3(0.0, 0.0, 0.2)


def _add(a: Vec3, b: Vec3) -> Vec3:
    return Vec3(a.x + b.x, a.y + b.y, a.z + b.z)


def _sub(a: Vec3, b: Vec3) -> Vec3:
    return Vec3(a.x - b.x, a.y - b.y, a.z - b.z)


def _scale(a: Vec3, factor: float) -> Vec3:
    return Vec3(a.x * factor, a.y * factor, a.z * factor)


def _dot(a: Vec3, b: Vec3) -> float:
    return a.x * b.x + a.y * b.y + a.z * b.z


def _length(a: Vec3) -> float:
    return math.sqrt(_dot(a, a))


def _jitter(context: TraceContext) -> float:
    context.random_state = (1103515245 * context.random_state + 12345) & 0x7FFFFFFF
    return 1.0 - context.random_state / 0x3FFFFFFF


def _distributed_vector(context: TraceContext, normal: Vec3, sa: float, sb: float) -> Vec3:
    if abs(normal.z) > EPSILON:
        a = Vec3(normal.y * normal.z, -normal.x * normal.z, 0.0)
        b = Vec3(a.y * normal.z, -a.x * normal.z, a.x * normal.y - a.y * normal.x)
    else:
        a = Vec3(normal.y, -normal.x, 0.0)
        b = Vec3(0.0, 0.0, 1.0)
    normal_length = _length(normal)
    a = _scale(a, sa * (normal_length / _length(a)) * _jitter(context))
    b = _scale(b, sb * (normal_length / _length(b)) * _jitter(context))
    return _add(a, b)


def _reflect(incident: Vec3, normal: Vec3) -> Vec3:
    factor = -2.0 * _dot(incident, normal) / _dot(normal, normal)
    return _add(incident, _scale(normal, factor))


def _intersect(origin: Vec3, direction: Vec3) -> tuple[float, Vec3, Vec3, Texture | None]:
    distance = -1.0
    point = Vec3(0.0, 0.0, 0.0)
    normal = Vec3(0.0, 0.0, 0.0)
    texture: Texture | None = None
    if abs(direction.z) > EPSILON:
        candidate = -origin.z / direction.z
        if EPSILON < candidate < MAX_T:
            distance = candidate
            point = _add(origin, _scale(direction, candidate))
            normal = Vec3(0.0, 0.0, 1.0)
            tile = (int(point.x + 50000.0) + int(point.y + 50000.0)) & 1
            texture = GROUND[tile]
    direction_scale = 1.0 / _dot(direction, direction)
    for sphere in SPHERES:
        relative_center = _sub(sphere.center, origin)
        projection = _dot(relative_center, direction) * direction_scale
        constant = (
            sphere.radius * sphere.radius - _dot(relative_center, relative_center)
        ) * direction_scale
        discriminant = constant + projection * projection
        if discriminant > 0.0:
            root = math.sqrt(discriminant)
            candidate = projection - root
            if candidate < EPSILON:
                candidate = projection + root
            if candidate > EPSILON and (candidate < distance or distance < 0.0):
                distance = candidate
                local_point = _scale(direction, candidate)
                normal = _sub(local_point, relative_center)
                point = _add(local_point, origin)
                texture = sphere.texture
    return distance, point, normal, texture


def _trace(context: TraceContext, origin: Vec3, direction: Vec3, recursion: int) -> Vec3:
    if recursion <= 0:
        return Vec3(0.0, 0.0, 0.0)
    use_distribution = (MAX_REC - recursion) < DIST_LEVELS
    distance, point, normal, texture = _intersect(origin, direction)
    if distance > EPSILON:
        assert texture is not None
        light_direction = _sub(LIGHT, point)
        light_dot_normal = _dot(light_direction, normal)
        intensity = 0.0
        if light_dot_normal > 0.0:
            shadow_count = 0
            if use_distribution:
                radius_scale = 0.4 / _length(light_direction)
                for _ in range(context.distribution):
                    offset = _distributed_vector(context, light_direction, radius_scale, radius_scale)
                    shadow_t, _, _, _ = _intersect(point, _add(light_direction, offset))
                    if shadow_t < EPSILON or shadow_t > 1.0:
                        shadow_count += 1
            else:
                shadow_t, _, _, _ = _intersect(point, light_direction)
                if shadow_t < EPSILON or shadow_t > 1.0:
                    shadow_count = context.distribution
            if shadow_count > 0:
                normalization = _dot(normal, normal) * _dot(light_direction, light_direction)
                intensity = (
                    light_dot_normal
                    / math.sqrt(normalization)
                    * texture.diffuse
                    * shadow_count
                    / context.distribution
                )
        color = _scale(texture.color, 0.3 + intensity)
        if texture.reflect > EPSILON:
            reflected = _reflect(direction, normal)
            reflected_color = Vec3(0.0, 0.0, 0.0)
            if use_distribution and texture.roughness > EPSILON:
                for _ in range(context.distribution):
                    offset = _distributed_vector(
                        context, reflected, texture.roughness, texture.roughness
                    )
                    reflected_color = _add(
                        reflected_color,
                        _trace(context, point, _add(reflected, offset), recursion - 1),
                    )
                reflected_color = _scale(
                    reflected_color, 1.0 / context.distribution
                )
            else:
                reflected_color = _trace(context, point, reflected, recursion - 1)
            color = _add(color, _scale(reflected_color, texture.reflect))
    else:
        horizontal = math.sqrt(direction.x * direction.x + direction.y * direction.y)
        if horizontal > 0.0:
            blend = math.atan(abs(direction.z) / horizontal) * 0.63661977
        else:
            blend = 1.0
        color = _add(
            _scale(SKY_ZENITH, blend),
            _scale(SKY_HORIZON, 1.0 - blend),
        )
    return Vec3(min(color.x, 1.0), min(color.y, 1.0), min(color.z, 1.0))


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or values is not None and (len(values) > MAX_PARSEABLE_INPUT_LENGTH
                                       or any(type(value) is not int
                                              or not -(1 << 63) <= value < (1 << 63)
                                              for value in values))
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if values is None or (input_length is not None and input_length != len(values)):
        return INVALID_RESULT, b""
    if len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    distribution, pixel_x, pixel_y = values
    if not MIN_DISTRIBUTION <= distribution <= MAX_DISTRIBUTION:
        return INVALID_RESULT, b""
    if not 0 <= pixel_x < WIDTH or not 0 <= pixel_y < HEIGHT:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""

    context = TraceContext(distribution)
    scale_x = (pixel_x - WIDTH // 2) / WIDTH
    scale_z = (HEIGHT // 2 - pixel_y) / HEIGHT
    direction = Vec3(
        CAMERA_RIGHT.x * scale_x + CAMERA_DIR.x + CAMERA_UP.x * scale_z,
        CAMERA_RIGHT.y * scale_x + CAMERA_DIR.y + CAMERA_UP.y * scale_z,
        CAMERA_RIGHT.z * scale_x + CAMERA_DIR.z + CAMERA_UP.z * scale_z,
    )
    pixel_color = Vec3(0.0, 0.0, 0.0)
    for _ in range(distribution):
        offset = _distributed_vector(context, direction, 0.5 / WIDTH, 0.5 / HEIGHT)
        pixel_color = _add(
            pixel_color,
            _trace(context, CAMERA, _add(direction, offset), MAX_REC),
        )
    pixel_color = _scale(pixel_color, 1.0 / distribution)
    channels = (
        int(pixel_color.x * 255.0) & 0xFE,
        int(pixel_color.y * 255.0) & 0xFE,
        int(pixel_color.z * 255.0) & 0xFE,
    )
    return 3, bytes(channels)
