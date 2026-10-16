"""Reference recurrence for the bounded Hilbert curve point-list benchmark."""

from __future__ import annotations

import struct

INVALID_RESULT = -1
MAX_OUTPUT_BYTES = 65536


def _curve(cx: int, cy: int, side: int, level: int, angle: int) -> list[tuple[int, int]]:
    q = side // 4
    points = [(cx + q, cy + q), (cx - q, cy + q), (cx - q, cy - q), (cx + q, cy - q)]
    angle %= 4
    points = points[angle:] + points[:angle]
    if level == 1:
        return points
    return (
        _curve(*points[0], side // 2, level - 1, angle + 1)[::-1]
        + _curve(*points[1], side // 2, level - 1, angle)
        + _curve(*points[2], side // 2, level - 1, angle)
        + _curve(*points[3], side // 2, level - 1, angle - 1)[::-1]
    )


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return INVALID_RESULT, b""
    level, angle = values
    if not 1 <= level <= 6 or not 0 <= angle <= 3:
        return INVALID_RESULT, b""
    scale = 1 << (level + 1)
    coords = [coordinate for point in _curve(0, 0, scale, level, angle) for coordinate in point]
    output = struct.pack("<" + "q" * len(coords), *coords)
    return len(output), output
