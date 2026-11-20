"""Direct, no-pyramid volume sampler used as an independent oracle."""

from __future__ import annotations

try:
    from .primary_oracle import MAX_PARSEABLE_INPUT_VALUES, Q8, Q16
except ImportError:
    from primary_oracle import MAX_PARSEABLE_INPUT_VALUES, Q8, Q16


def _round(n: int, d: int) -> int:
    return (n + d // 2) // d


def _decode(frame, is_null: bool, length: int | None):
    if (type(is_null) is not bool or is_null or not isinstance(frame, (list, tuple))
            or len(frame) > MAX_PARSEABLE_INPUT_VALUES):
        return None
    if length is None:
        length = len(frame)
    if (type(length) is not int or length != len(frame) or length < 3
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in frame)):
        return None
    side, ray_count, samples = frame[:3]
    if side not in (2, 4, 8) or not 1 <= ray_count <= 16 or not 1 <= samples <= 32:
        return None
    count = side * side * side
    if length != 3 + 2 * count + 6 * ray_count:
        return None
    cells = []
    at = 3
    for _ in range(count):
        opacity, color = frame[at], frame[at + 1]
        if not 0 <= opacity <= 255 or not 0 <= color <= 255:
            return None
        cells.append((opacity, color))
        at += 2
    rays = []
    limit = (side - 1) * Q8
    for _ in range(ray_count):
        ray = tuple(frame[at:at + 6])
        at += 6
        start, delta = ray[:3], ray[3:]
        if any(value < 0 or value > limit for value in start):
            return None
        if any(value < -limit or value > limit for value in delta):
            return None
        if samples > 1 and delta == (0, 0, 0):
            return None
        if any(not 0 <= start[a] + k * delta[a] <= limit
               for a in range(3) for k in range(samples)):
            return None
        rays.append((start, delta))
    return side, samples, cells, rays


def _sample(cells, side, point):
    ix, iy, iz = (coordinate // Q8 for coordinate in point)
    fx, fy, fz = (coordinate % Q8 for coordinate in point)
    ux, uy, uz = min(ix + 1, side - 1), min(iy + 1, side - 1), min(iz + 1, side - 1)
    opacity_total = 0
    color_total = 0
    for z, wz in ((iz, Q8 - fz), (uz, fz)):
        for y, wy in ((iy, Q8 - fy), (uy, fy)):
            for x, wx in ((ix, Q8 - fx), (ux, fx)):
                opacity, color = cells[(z * side + y) * side + x]
                weight = wx * wy * wz
                opacity_total += weight * opacity
                color_total += weight * opacity * color
    opacity_q = _round(opacity_total * Q16, 255 * (1 << 24))
    color_q = _round(color_total * Q16, 255 * 255 * (1 << 24))
    return opacity_q, color_q


def _render_one(cells, side, samples, start, delta):
    alpha = color = 0
    processed = 0
    for k in range(samples):
        processed += 1
        location = tuple(start[axis] + k * delta[axis] for axis in range(3))
        sample_alpha, sample_color = _sample(cells, side, location)
        visibility = Q16 - alpha
        alpha = min(Q16, alpha + _round(visibility * sample_alpha, Q16))
        color = min(Q16, color + _round(visibility * sample_color, Q16))
        if alpha == Q16:
            break
    component = (color * 255 + Q16 // 2) // Q16
    coverage = (alpha * 255 + Q16 // 2) // Q16
    return bytes((component, component, component, coverage, processed))


def expected_output(frame, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    decoded = _decode(frame, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    side, samples, cells, rays = decoded
    required = 5 * len(rays)
    if output_is_null:
        return -2, b""
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < required):
        return -3, b""
    output = b"".join(
        _render_one(cells, side, samples, start, delta)
        for start, delta in rays)
    return required, output
